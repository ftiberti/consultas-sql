
with a as (
	select 
	mc.store_id,
	mc.plan_id,
	mc.created_at,
	si.first_payment,
	si.country,
    si.churned_at,
	row_number() over (partition by mc.store_id order by mc.created_at desc) rank_fecha
	from tiendanube.mwp_contracts mc 
	left join tiendanube.mwp_store_info si on si.id = mc.store_id 
	where mc.created_at < '{query_cutoff}'
	and mc.deleted_at is null
	and (si.churned_at is null or si.churned_at >= '{fd_last_month}') 
	and si.state <> 4
	and mc.plan_id is not null
	and mc.store_id not in ( 
	    SELECT 
	    distinct tg.related_id
	    FROM tiendanube.mwp_tags tg
	    WHERE tg."type" = 'store' 
	    AND (tg."tag" = 'sre-block-store-429' OR tg."tag" = 'sre-block-store-404'))
	),
--usamos esto para sacar phoenix
churn_contracts as (
	select 
	store_id,
	true as churn,
    created_at,
    end_date
	from (
		select 
		mc.store_id,
		mc.created_at,
        mc.end_date, --esta es la fecha real de churn de los contratos de pre-churn%, es la que vamos a usar para nuestro churned_at en los casos de phoenix
		mc."type",
		row_number() over (partition by mc.store_id order by mc.created_at desc) rank_fecha --ordenamos por created_at porque queremos ver los contratos en orden cronologico de creacion, para quedarnos con el mas actualizado
		from tiendanube.mwp_contracts mc 
		where mc.start_date < '{query_cutoff}' --para evitar problemas con contratos desfazados (ver chat con guti 6/3/23), buscamos todos aquellos con fecha de comienzo antes de la fecha de corte. Con esto, seleccionamos correctamente a los phoenix, evitando traer los contratos de pago que no se hayan hecho en el mes de interes
		and mc.deleted_at is null)
	where rank_fecha = 1
	and "type" like 'pre-churn%'),
	
ventas_l90d as (
	select 
	o.store_id,
	count(distinct o.id) sales_90d
	from tiendanube.mwp_orders o
	WHERE o.storefront in ('store', 'facebook', 'mobile', 'form', 'social', 'mobile_keyboard', 'api', 'permalink') 
	AND o.completed_at between dateadd(day,-90,'{query_cutoff}') and '{query_cutoff}'
	AND o.payment_status = 'paid' 
	AND o.status <> 'cancelled' 
	AND o.order_id IS NOT NULL 
	AND o.total_in_usd <= 30000 
	group by 1),
	
month_on_platform_sales as (
	select 
	o.store_id,
	count(distinct o.id) month_on_platform_sales
	from tiendanube.mwp_orders o
	WHERE o.storefront in ('mobile', 'store', 'form', 'social') 
	AND o.completed_at between '{fd_last_month}' and '{query_cutoff}'
	AND o.payment_status = 'paid' 
	AND o.status <> 'cancelled' 
	AND o.order_id IS NOT NULL 
	AND o.total_in_usd <= 30000 
	group by 1),
	
month_gmv as (
	select 
	o.store_id,
	case 
		when o.currency = 'BRL' then 'BR'
		when o.currency = 'ARS' then 'AR'
		when o.currency = 'PEN' then 'PE'
		when o.currency = 'MXN' then 'MX'
		when o.currency = 'CLP' then 'CL'
		when o.currency = 'COP' then 'CO'
		else 'other_currency' end country_currency, --updatear a medida que tengamos más países
	sum(case when o.storefront in ('mobile', 'store', 'form', 'social') then o.total end) month_on_platform_gmv,
	sum(case when o.storefront not in ('mobile', 'store', 'form', 'social') then o.total end) month_off_platform_gmv
	from tiendanube.mwp_orders o
	WHERE o.completed_at between '{fd_last_month}' and '{query_cutoff}'
	AND o.payment_status = 'paid' 
	AND o.status <> 'cancelled' 
	AND o.order_id IS NOT NULL 
	AND o.total_in_usd <= 30000 
	group by 1,2)

select
a.store_id,
a.plan_id,
pg.grupo grouping_plan,
case 
	when pg.grupo = 'enterprise' then 'MM'
	when pg.grupo = 'freemium' then 'FREEMIUM'
	else 'SMB' end finance_plan_group,
coalesce(ventas_l90d.sales_90d,0) sales_90d,
case 
	when ventas_l90d.sales_90d > 1500 then 'top-seller'
	when ventas_l90d.sales_90d between 751 and 1500 then 'large-seller'
	when ventas_l90d.sales_90d between 151 and 750 then 'medium-seller'
	when ventas_l90d.sales_90d between 31 and 150 then 'small-seller'
	when ventas_l90d.sales_90d between 7 and 30 then 'tiny-seller'
	when ventas_l90d.sales_90d between 1 and 6 then 'struggling-seller'
	else 'no-seller' end segment,
a.first_payment,
a.country,
coalesce(s.sessions,0) month_sessions,
coalesce(ops.month_on_platform_sales,0) month_on_platform_sales,
coalesce(mg.month_on_platform_gmv,0) month_on_platform_gmv_lc,
coalesce(mg.month_off_platform_gmv,0) month_off_platform_gmv_lc,
mn.merchant_name,
case 
	when (a.churned_at >= '{fd_last_month}' and a.churned_at < '{query_cutoff}') then a.churned_at
	when (churn_contracts.end_date >= '{fd_last_month}' and churn_contracts.end_date < '{query_cutoff}') then churn_contracts.end_date::timestamp --aca efectivamente marcamos a los phoenix que tengan end_date dentro del mes de interes
    else null end churned_at
from a 
left join churn_contracts on churn_contracts.store_id = a.store_id
left join tableau_external.gs_misc_plan_grouping pg on pg.plan = a.plan_id
left join ventas_l90d on ventas_l90d.store_id = a.store_id
left join (
	select 
	s.store_id,
	count(distinct s.session_id) sessions
	from storefronts.sessions s
	where "timestamp" between '{fd_last_month}' and '{query_cutoff}'
	group by 1) s on s.store_id = a.store_id
left join (
    select 
    mt.related_id as store_id,
    mt."tag" merchant_name
    from tiendanube.mwp_tags as mt
    where (mt."tag" like 'franchise-%' or mt."tag" like 'group-%') 
    and mt."tag" not like '%franchise-main%'
    and mt.type = 'store') mn on mn.store_id = a.store_id
left join month_on_platform_sales ops on ops.store_id = a.store_id
left join month_gmv mg on mg.store_id = a.store_id and mg.country_currency = a.country --solo traemos gmv de ordenes pagadas con la currency local de la tienda
where a.rank_fecha = 1
and (churn_contracts.churn is null or churn_contracts.end_date >= '{fd_last_month}') --solo nos interesan end_dates del mes de interes, ya que esa es nuestra fecha de churn
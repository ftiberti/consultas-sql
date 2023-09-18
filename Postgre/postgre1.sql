tienda_nube_tunnel.revenue_by_store

tienda_nube_tunnel.segmentation_track

--info de conciliacion con Mercado pago
tienda_nube_tunnel.settlement_report


SELECT 
DATE_FORMAT(o.paid_at, "%Y-%m") as mon,
o.currency,
case when o.should_charge = 0 then 'split' else 'manual' end as cpt_type,
SUM(CASE Po
		when o.transaction_fee_type = 'FIXED_VALUE' then o.transaction_fee
		else o.transaction_fee * o.paid_value
	end) as cpt,
count(distinct o.store_id) total_transaction_fees
FROM orders o 
WHERE o.paid_at >= '2020-01-01'
group by 1,2,3




select 	 fecha
		,st.finance_plan_group
		,sum(st.month_on_platform_gmv_lc)
		,count(*)
		,sum(if(st.month_on_platform_gmv_lc = 0, 1,0)) as cuentas_con_gmv_0
from tienda_nube_tunnel.segmentation_track st 
where country = 'MX' and (fecha = '2023-07-31' or fecha = '2023-08-31')
group by 1,2



select fecha
	  ,st.finance_plan_group
	  ,st.month_on_platform_gmv_lc
from tienda_nube_tunnel.segmentation_track st 
where country = 'MX' 
  and (fecha = '2023-07-31' or fecha = '2023-08-31')
  and st.finance_plan_group = 'FREEMIUM'

  
  
  
  
select * 
from tienda_nube_tunnel.segmentation_track st
where store_id  = 986479


SELECT 
rs.*,
st.plan_id,
st.grouping_plan,
st.finance_plan_group,
st.sales_90d,
st.segment,
st.month_sessions as sessions,
st.month_on_platform_sales as transactions,
st.month_on_platform_gmv_lc as gmv_on_platform, 
st.month_off_platform_gmv_lc as gmv_off_platform
FROM tienda_nube_tunnel.revenue_by_store rs 
left join tienda_nube_tunnel.segmentation_track st ON st.store_id = rs.store_id and st.fecha = cast(rs."date" as date) and st.country = rs.country
where rs.store_id = 986479


select mps.plan_id, mpc.monthly, sum(mps.price) 
from tiendanube.mwp_payments mp 
inner join tiendanube.mwp_payment_stores mps on mp.id = mps.payment_id
inner join tiendanube.mwp_plans_countries mpc on mps.plan_id = mpc.id 
---inner join tiendanube.mwp_plans mp2 on mpc.id = mp2.id 
where mp.currency = 'BRL' 
and mp.state = 2
and cast(mp.paid_at as date) between '2023-07-01' and '2023-07-31'
and mp.bill_sent = 1
group by 1,2
order by 2 desc

--------------------------
facturacion

select * from tiendanube.mwp_invoices mi 
inner join tiendanube.mwp_payments mp on mp.id = mi.payment_id 
--inner join tiendanube.mwp_payment_transaction_fees mptf on mptf.payment_id = mp.id 
where mi."date" between '2023-08-01' and '2023-08-31'
and mi.currency = 'ARS'


select inv.id 	
	  ,inv.amountcurrency 
	  ,inv.authorizedat 
	  ,inv.invoiceinformationid 
	  ,inv.afipdetailid 
	  ,inv.pdfid 
from billing.invoice inv  
limit 10


select c.*
from billing. c    
limit 10

select * from tiendanube.mwp_contracts mc 
where mc.store_id = 986479
order by start_date asc 

select mo.cancelled_at , mo.cancel_reason ,mo.* from tiendanube.mwp_orders mo where mo.store_id = 986479 
order by created_at desc 
limit 10
 
select mp.paid_at ,mptf.*
from tiendanube.mwp_payments mp 
left join tiendanube.mwp_payment_transaction_fees mptf on mp.id = mptf.payment_id 
where mp.store_id = 263645
  and mp.state =2
order by mp.paid_at desc


select mo.*
from tiendanube.mwp_orders mo  
where mo.store_id = 986479
order by mo.created_at desc 
limit 10

select * from tiendanube.mwp_store_info msi where msi.id = 986479

select * from tiendanube.mwp_contracts mc 
where mc.store_id in (1612749)
--and mc.start_date >= '2023-08-01'
order by mc.store_id, start_date 




select *
from tiendanube.mwp_contracts msi 
where store_id = 3068525
order by start_date 
limit 40

1 - chequear bill_sent en tabla de payments
2 - busco payment_store_id desde la tabla de contracts
3 - con ese payment_store_id, busco en la tabla de payments
4 - me fijo en esa tabla el bill_sent (si esta en 0, es que no se facturo)



Para Chile sólo miramos Subscriptions revenue
Y esa tienda, pagó en abril el plan
Por ende no lo vamos a ver en agosto
Y el GMV es indiferente porque no estamos mirando CPT para Chile


Store_id 2180393, 2375831, 2668882 de Chile y store_id 2460089 de Colombia, MM, tienen GMV, no están en Tableau de Revenues. 
no, PORQUE LA EXPLICACION DE ABAJO ENTRE LAS LINEAS

Freemium. Vemos varias que tienen GMV pero no generan Revenue. Un ejemplo store 3068525.
si es freemium y no usa nube pago (sino que usa pago personalizado), no se deberia cobrar el CPT? --> pregunta para BILLING


------
AR y BR, subscriptions, cpt, rebates
MX subscriptions y rebates
CO, CL subscriptions
MX CO CL son los pagos del mes en que se realizaron
------



select * from tiendanube.mwp_store_info msi2 
where 1=1 --msi2.country = 'AR'
--and state <> 4
and msi2.id = 3068525
and msi2.id in (select related_id from tiendanube.mwp_tags 
where "tag" in ('sre-block-store-404', 'sre-block-store-404 ', 'sre-block-store-429'))



select *
from tiendanube.mwp_payment_stores mps  
where id = 5094110
order by created_at 



select *
from tiendanube.mwp_payments mp 
where id = 7312461
order by created_at 


select * from tiendanube.paid_orders_store_info posi 
where posi.store_id = 3068525
order by completed_at desc 
limit 100
---cpt $0 campo payment con nuvem-pago OK
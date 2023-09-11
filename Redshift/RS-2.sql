select exchange_rate * 10000 as tasa
		,*
from tiendanube.mwp_currencies mc 




select *
from tiendanube.paid_orders_store_info posi 
where store_id = 767
  and posi.completed_at between '2023-08-01' and '2023-08-31'
 
  
select *
from tiendanube.mwp_orders mo 

--------

select sum(ptf.price)
FROM tiendanube.mwp_payment_transaction_fees ptf
LEFT JOIN tiendanube.mwp_payments mp ON ptf.payment_id = mp.id
where mp.state = 2 
and cast(mp.paid_at as date) between '2023-08-01' and '2023-08-31'
and mp.currency = 'BRL'

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


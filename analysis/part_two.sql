   
with ranked AS (
    SELECT
        client_id
       ,purchases_sk
       ,CAST(time_purchased AS DATE)
       ,category
       ,RANK() OVER (
        PARTITION BY client_id
        ORDER BY CAST(time_purchased AS DATE) ASC
       ) purchase_rank
    
   FROM {ref('purchases_transformed')}}
   WHERE is_refunded = 0 
   ORDER BY client_id
),

next AS (

SELECT
       client_id
       ,purchases_sk
       ,time_purchased
       ,category
       ,purchase_rank
       ,LEAD(category,1) OVER (
           PARTITION BY client_id
           ORDER BY purchase_rank
       ) next_category
       ,LEAD(time_purchased,1) OVER (
           PARTITION BY client_id
           ORDER BY purchase_rank
       ) next_time_purchased
FROM ranked
),

same_category AS (
SELECT
       client_id
       ,purchases_sk
       ,category
       ,DATE_PART('day', next_time_purchased::timestamp - time_purchased::timestamp) AS days_difference

FROM next
WHERE purchase_rank = 1 
  AND next_category IS NOT NULL
  AND category = next_category

),


different_category AS (
SELECT
       client_id
       ,purchases_sk
       ,category
       ,next_category
FROM next
WHERE purchase_rank = 1 
  AND next_category IS NOT NULL
  AND category != next_category
)


/*SELECT 
    category
    ,MAX( days_difference) AS max_to_next_purchase
    ,ROUND(AVG( days_difference)) AS avg_to_next_purchase
FROM same_category
GROUP BY category */


SELECT
     category
     ,next_category
     ,COUNT(purchases_sk) AS count_of_snd_purchases
FROM different_category
GROUP BY category, next_category
ORDER BY category, COUNT(purchases_sk) DESC







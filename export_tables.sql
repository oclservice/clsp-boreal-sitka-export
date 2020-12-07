-- 1) export items

--KEEP
\o OCUL_LU_items.csv

COPY (
  WITH items AS (SELECT co.*, ca.label, ca.label_class, ca.record, ou.name AS libraryname, cl.name AS copylocation, st.name AS statusname
    FROM config.copy_status st, asset.copy co, asset.call_number ca, actor.org_unit ou, asset.copy_location cl
    WHERE co.deleted IS FALSE
      AND circ_lib IN (105,113,130,104,108,103,132,151,131,150,107,117)
      AND ca.owning_lib IN (105,113,130,104,108,103,132,151,131,150,107,117)
      AND ca.deleted IS FALSE
      AND co.call_number = ca.id
      AND co.circ_lib = ou.id
      AND co.location = cl.id
      AND co.status = st.id
      AND ou.opac_visible IS TRUE
  ), circs AS (
    SELECT target_copy As item, COUNT(*) AS num_circs
    FROM action.circulation
    GROUP BY target_copy
  ), last_circ AS (
    SELECT target_copy AS item, MAX(checkin_time) AS last_circ
    FROM action.circulation
    GROUP BY target_copy
  ), inhouses AS (
    SELECT item, COUNT(*) AS num_inhouse
    FROM action.in_house_use
    GROUP BY item
  ), last_inhouse AS (
    SELECT item, MAX(use_time) AS last_inhouse
    FROM action.in_house_use
    GROUP BY item
  )
  SELECT items.*, circs.num_circs, last_circ.last_circ, inhouses.num_inhouse, last_inhouse.last_inhouse
  FROM items
    LEFT JOIN circs ON circs.item = items.id
    LEFT JOIN last_circ ON last_circ.item = items.id
    LEFT JOIN inhouses ON inhouses.item = items.id
    LEFT JOIN last_inhouse ON last_inhouse.item = items.id
)
TO STDOUT WITH (DELIMITER ',', FORMAT CSV, HEADER TRUE);

\o

--patrons
CREATE OR REPLACE VIEW conifer.usr_with_authname AS 
  SELECT DISTINCT id, card, profile, usrname, email, passwd, standing,
  ident_type, ident_value, ident_type2, ident_value2, net_access_level,
  photo_url, prefix, first_given_name, second_given_name, family_name, suffix,
  alias, day_phone, evening_phone, other_phone, mailing_address,
  billing_address, home_ou, dob, active, master_account, super_user, barred,
  deleted, juvenile, usrgroup, claims_returned_count, credit_forward_balance,
  last_xact_id, REGEXP_REPLACE(alert_message, '\n', ' ', 'g') AS alert_message,
  create_date, expire_date, claims_never_checked_out_count, last_update_time,
  pref_prefix, pref_first_given_name, pref_second_given_name, pref_family_name,
  pref_suffix, name_keywords, name_kw_tsvector, guardian,
  COALESCE(REGEXP_REPLACE(email, '^(.*?)@(laurentian.ca|laurentienne.ca|huntingtonu.ca|usudbury.ca)', '\1'), email, usrname) AS authname
  FROM actor.usr au
  WHERE au.deleted IS FALSE
    AND (
      EXISTS (
        SELECT 1 FROM 
        action.circulation ac
        WHERE au.id = ac.usr
          AND ac.xact_start > '2011-09-01'::DATE
      )
    OR (au.profile IN (3, 111, 131))
    OR (au.profile = 129 AND create_date > '2017-01-01'::DATE )
  )
  ORDER BY au.id;

--KEEP
\o OCUL_LU_patron.csv

COPY (
  SELECT *
  FROM conifer.usr_with_authname
  WHERE home_ou IN (105,113,130,104,108,103,132,151,131,150,107,117)
)
TO STDOUT WITH (DELIMITER ',', FORMAT CSV, HEADER TRUE);

\o

--patron barcodes
--KEEP
\o OCUL_LU_patron_barcode.csv 

COPY (
  SELECT *
  FROM actor.card ac
  WHERE active IS TRUE
    AND EXISTS (
      SELECT 1
      FROM conifer.usr_with_authname
      WHERE card = ac.id
      AND home_ou IN (105,113,130,104,108,103,132,151,131,150,107,117)
  )
)
TO STDOUT WITH (DELIMITER ',', FORMAT CSV, HEADER TRUE);

\o

--patron address
--KEEP
\o OCUL_LU_patron_address.csv

COPY (
  SELECT *
  FROM actor.usr_address aua
  WHERE EXISTS (
    SELECT 1
    FROM conifer.usr_with_authname au
    WHERE au.id = aua.usr
      AND home_ou IN (105,113,130,104,108,103,132,151,131,150,107,117)
  )
)
TO STDOUT WITH (DELIMITER ',', FORMAT CSV, HEADER TRUE);

\o

--patron stat cats
--KEEP
\o OCUL_LU_preferred_language.csv

COPY (
  SELECT m.target_usr AS usr, st.name,ste.value
  FROM actor.stat_cat st, actor.stat_cat_entry ste, conifer.usr_with_authname u, actor.stat_cat_entry_usr_map m
  WHERE u.id = m.target_usr
  AND u.deleted IS FALSE
  AND m.stat_cat = st.id
  AND m.stat_cat_entry = ste.value
  AND m.stat_cat = ste.stat_cat
  AND EXISTS  (
    SELECT 1
    FROM conifer.usr_with_authname au
    WHERE au.id = m.target_usr
    AND home_ou IN (105,113,130,104,108,103,132,151,131,150,107,117)
  )
)
TO STDOUT WITH (DELIMITER ',', FORMAT CSV, HEADER TRUE);

\o

--export holds

--KEEP
\o OCUL_LU_hold.csv

COPY (
  SELECT ahr.*, aou.name AS request_library, aou2.name AS pickup_library
  FROM action.hold_request ahr
    INNER JOIN actor.org_unit aou ON ahr.request_lib = aou.id
    INNER JOIN actor.org_unit aou2 ON ahr.pickup_lib = aou2.id
  WHERE request_lib IN (105,113,130,104,108,103,132,151,131,150,107,117)
    AND capture_time IS NOT NULL
    AND cancel_time IS NULL
    AND fulfillment_time IS NULL
    AND (expire_time > now() or expire_time IS NULL)
) TO STDOUT (DELIMITER ',', FORMAT CSV, HEADER TRUE);

\o

--export circ
--KEEP
\o OCUL_LU_circ.csv

COPY (
  SELECT ac.*, aou.name AS libraryname
  FROM action.circulation ac
    INNER JOIN actor.org_unit aou ON ac.circ_lib = aou.id
  WHERE circ_lib IN (105,113,130,104,108,103,132,151,131,150,107,117)
  AND checkin_time IS NULL
)
TO STDOUT WITH (DELIMITER ',', FORMAT CSV, HEADER TRUE);

\o

--fines

SELECT count(*) FROM money.billable_xact_summary_location_view  WHERE billing_location IN (105,113,130,104,108,103,132,151,131,150,107,117) AND balance_owed  != 0 ;

SELECT count(distinct usr) FROM money.billable_xact_summary_location_view  WHERE billing_location IN (105,113,130,104,108,103,132,151,131,150,107,117) AND balance_owed != 0 ;

DROP TABLE mlb.laurentian_fines;
CREATE TABLE mlb.laurentian_fines AS
  SELECT mv.*, aou.name AS libraryname
  FROM money.billable_xact_summary_location_view mv
  INNER JOIN actor.org_unit aou ON mv.billing_location = aou.id
  WHERE billing_location IN (105,113,130,104,108,103,132,151,131,150,107,117)
    AND balance_owed != 0
  ORDER BY usr;

ALTER TABLE mlb.laurentian_fines add column title text;
ALTER TABLE mlb.laurentian_fines add column barcode text;
--grab title 
UPDATE mlb.laurentian_fines a
SET title =  r.title
FROM reporter.super_simple_record r, action.circulation ci, asset.copy co, asset.call_number ca
WHERE a.id = ci.id
  AND ci.target_copy = co.id
  AND co.call_number = ca.id
  AND ca.record = r.id;

UPDATE mlb.laurentian_fines a
SET barcode =  co.id
FROM action.circulation ci, asset.copy co
WHERE a.id = ci.id
AND ci.target_copy = co.id ;

--KEEP
\o OCUL_LU_fines.csv

COPY (
  SELECT id, usr, xact_start, xact_finish, total_paid, last_payment_ts,
  REGEXP_REPLACE(last_payment_note, '\n', ' ', 'g') AS last_payment_note,
  last_payment_type, total_owed, last_billing_ts,
  REGEXP_REPLACE(last_billing_note, '\n', ' ', 'g') AS last_billing_note,
  last_billing_type, balance_owed, xact_type, billing_location, libraryname,
  title, barcode
 FROM mlb.laurentian_fines WHERE balance_owed > 0 ORDER BY usr
)
TO STDOUT WITH (DELIMITER ',', FORMAT CSV, HEADER TRUE);

\o

--codes

--P2E
--KEEP
\o OCUL_LU_p2e.csv

COPY (
  SELECT acn.record, 'Portfolio' AS resource_type
  FROM asset.call_number acn
    INNER JOIN biblio.record_entry bre ON bre.id = acn.record
  WHERE acn.deleted IS FALSE
    AND bre.deleted IS FALSE
    AND acn.owning_lib IN (105,113,130,104,108,103,132,151,131,150,107,117)
    AND acn.label = '##URI##'
  ORDER BY acn.record
)
TO STDOUT WITH (DELIMITER ',', FORMAT CSV, HEADER FALSE);

\o


-- 1) export items

\copy (
  SELECT co.*, ca.label, ca.label_class, ca.record, ou.name AS libraryname, cl.name AS copylocation, st.name AS statusname
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
) TO OCUL_LU_items.csv delimiter ',' CSV header

--item notes

\copy (
  SELECT * 
  FROM asset.copy_note
  WHERE owning_copy IN (
    SELECT id
    FROM asset.copy 
    WHERE deleted IS FALSE
      AND circ_lib IN (105,113,130,104,108,103,132,151,131,150,107,117)
      AND call_number IN (
        SELECT id
        FROM asset.call_number
        WHERE deleted IS FALSE
          AND owning_lib IN (105,113,130,104,108,103,132,151,131,150,107,117)
      )
  )
) TO OCUL_LU_item_notes.csv delimiter ',' CSV header
-- COPY 385

--item stat cats

\copy (
  SELECT s.name, e.value, c.owning_copy
  FROM asset.stat_cat s, asset.stat_cat_entry e, asset.stat_cat_entry_copy_map c
  WHERE s.id = e.stat_cat
    AND e.id = c.stat_cat_entry
    AND c.owning_copy IN (
      SELECT id
      FROM asset.copy
      WHERE deleted IS FALSE
        AND circ_lib IN (105,113,130,104,108,103,132,151,131,150,107,117)
        AND call_number IN (
          SELECT id
          FROM asset.call_number
          WHERE deleted IS FALSE
            AND owning_lib IN (105,113,130,104,108,103,132,151,131,150,107,117)
      )
  )
) TO OCUL_LU_item_stats.csv delimiter ',' CSV header
-- COPY 29229

-- 3) export the patron data

--patrons
CREATE OR REPLACE VIEW conifer.usr_with_authname AS 
  SELECT DISTINCT au.*, COALESCE(REGEXP_REPLACE(email, '^(.*?)@(laurentian.ca|laurentienne.ca|huntingtonu.ca|usudbury.ca)', '\1'), email, usrname) AS authname
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

\copy (
  SELECT *
  FROM conifer.usr_with_authname
  WHERE home_ou IN (105,113,130,104,108,103,132,151,131,150,107,117)
) TO OCUL_LU_patron.csv delimiter ',' CSV header
-- COPY 10943

--patron barcodes
\copy (
  SELECT *
  FROM actor.card ac
  WHERE active IS TRUE
    AND EXISTS (
      SELECT 1
      FROM conifer.usr_with_authname
      WHERE card = ac.id
      AND home_ou IN (105,113,130,104,108,103,132,151,131,150,107,117)
  )
) TO OCUL_LU_patron_barcode.csv delimiter ',' CSV header
-- COPY 77728

--patron settings

\copy (
  SELECT *
  FROM actor.usr_setting aus
  WHERE EXISTS (
    SELECT 1
    FROM conifer.usr_with_authname au
    WHERE au.id = aus.usr
      AND home_ou IN (105,113,130,104,108,103,132,151,131,150,107,117)
  )
) TO OCUL_LU_patron_setting.csv delimiter ',' CSV header
-- COPY 1297

--patron notes

\copy (
  SELECT *
  FROM actor.usr_note aun
  WHERE EXISTS (
    SELECT 1
    FROM conifer.usr_with_authname au
    WHERE au.id = aun.usr
      AND home_ou IN (105,113,130,104,108,103,132,151,131,150,107,117)
  )
) TO OCUL_LU_patron_notes.csv delimiter ',' CSV header
-- COPY 1987

--patron address

\copy (
  SELECT *
  FROM actor.usr_address aua
  WHERE EXISTS (
    SELECT 1
    FROM conifer.usr_with_authname au
    WHERE au.id = aua.usr
      AND home_ou IN (105,113,130,104,108,103,132,151,131,150,107,117)
  )
) TO OCUL_LU_patron_address.csv delimiter ',' CSV header
-- COPY 25395

--patron stat cats
\copy (
  SELECT m.target_usr, st.name,ste.value
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
) TO OCUL_LU_patron.stat_cat.csv delimiter ',' csv header
-- 19299

--patron bookbags

\copy (
  SELECT target_biblio_record_entry, barcode, name, title
  FROM container.biblio_record_entry_bucket c, container.biblio_record_entry_bucket_item i, reporter.super_simple_record r, conifer.usr_with_authname u, actor.card ca
  WHERE btype = 'bookbag'
    AND home_ou IN (105,113,130,104,108,103,132,151,131,150,107,117)
    AND c.id = i.bucket
    AND i.target_biblio_record_entry = r.id
    AND owner = u.id
    AND u.card = ca.id
    ORDER BY owner, name, title
) TO OCUL_LU_patron_bookbags.csv delimiter ',' csv header
-- 30775

--export holds

--check for holds WHERE the pickup lib is not an algoma one
SELECT count(*) FROM action.hold_request WHERE request_lib IN (105,113,130,104,108,103,132,151,131,150,107,117) AND pickup_lib not IN (105,113,130,104,108,103,132,151,131,150,107,117) AND cancel_time IS NULL AND fulfillment_time IS NULL;
-- count 
---------
--     0
--(1 row)

-- conifer=# SELECT count(*) FROM action.hold_request WHERE request_lib IN (105,113,130,104,108,103,132,151,131,150,107,117) AND cancel_time IS NULL AND fulfillment_time IS NULL AND (expire_time > now() or expire_time IS NULL);
-- count 
---------
--    17

\copy (
  SELECT ahr.*, aou.name AS libraryname
  FROM action.hold_request ahr
    INNER JOIN actor.org_unit aou ON ahr.request_lib = aou.id
  WHERE request_lib IN (105,113,130,104,108,103,132,151,131,150,107,117)
    AND capture_time IS NOT NULL
    AND cancel_time IS NULL
    AND fulfillment_time IS NULL
    AND (expire_time > now() or expire_time IS NULL)
) TO OCUL_LU_hold.csv delimiter ',' CSV header
-- COPY 17

--export circ

\copy (
  SELECT ac.*, aou.name AS libraryname
  FROM action.circulation ac
    INNER JOIN actor.org_unit aou ON ac.circ_lib = aou.id
  WHERE circ_lib IN (105,113,130,104,108,103,132,151,131,150,107,117)
  AND checkin_time IS NULL
) TO OCUL_LU_circ.csv delimiter ',' CSV header
-- COPY 3398

--fines

SELECT count(*) FROM money.billable_xact_summary_location_view  WHERE billing_location IN (105,113,130,104,108,103,132,151,131,150,107,117) AND balance_owed  != 0 ;
-- count 
---------
--  5381
--(1 row)

SELECT count(distinct usr) FROM money.billable_xact_summary_location_view  WHERE billing_location IN (105,113,130,104,108,103,132,151,131,150,107,117) AND balance_owed != 0 ;
--  count 
-- -------
--    2338

DROP TABLE mlb.laurentian_fines;
CREATE TABLE mlb.laurentian_fines AS
  SELECT mv.*, aou.name AS libraryname
  FROM money.billable_xact_summary_location_view mv
  INNER JOIN actor.org_unit aou ON mv.billing_location = aou.id
  WHERE billing_location IN (105,113,130,104,108,103,132,151,131,150,107,117)
    AND balance_owed !=
  0 ORDER BY usr;
-- SELECT 5377

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
-- UPDATE 4032

UPDATE mlb.laurentian_fines a
SET barcode =  co.id
FROM action.circulation ci, asset.copy co
WHERE a.id = ci.id
AND ci.target_copy = co.id ;
--UPDATE 4032


\copy (SELECT * FROM mlb.laurentian_fines ORDER BY usr) TO OCUL_LU_fines.csv delimiter ',' CSV header
-- COPY 5377

--codes

--org units
\copy (SELECT * FROM actor.org_unit ORDER BY id) TO OCUL_LU_org.csv delimiter ',' CSV header
-- COPY 49

--patron profile types
\copy (SELECT * FROM permission.grp_tree ORDER BY id) TO OCUL_LU_patrontype.csv delimiter ',' CSV header
-- COPY 35

--item circ modifiers
\copy (SELECT * FROM config.circ_modifier ORDER BY code) TO OCUL_LU_item_circ_modifiers.csv delimiter ',' CSV header
-- COPY 90

--item locations
\copy (SELECT * FROM asset.copy_location ORDER BY owning_lib, name) TO OCUL_LU_item_location.csv delimiter ',' CSV header
-- COPY 815


--item status
\copy (SELECT * FROM config.copy_status) TO OCUL_LU_item_status.csv delimiter ',' CSV header
-- COPY 20

--P2E
\copy (
  SELECT acn.record, 'Portfolio' AS resource_type
  FROM asset.call_number acn
    INNER JOIN biblio.record_entry bre ON bre.id = acn.record
  WHERE acn.deleted IS FALSE
    AND bre.deleted IS FALSE
    AND acn.owning_lib IN (105,113,130,104,108,103,132,151,131,150,107,117)
    AND acn.label = '##URI##'
  ORDER BY acn.record
) TO OCUL_LU_p2e.csv DELIMITER ',' CSV header


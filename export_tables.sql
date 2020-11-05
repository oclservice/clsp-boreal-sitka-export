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
) to items.csv delimiter ',' CSV header

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
) to item_notes.csv delimiter ',' CSV header
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
) to item_stats.csv delimiter ',' CSV header
-- COPY 29229

3) export the patron data

--patrons

\copy (
  SELECT *
  FROM actor.usr
  WHERE deleted IS FALSE
    AND home_ou IN (105,113,130,104,108,103,132,151,131,150,107,117)
) to patron.csv delimiter ',' CSV header
-- COPY 77658

--patron barcodes
\copy (
  SELECT *
  FROM actor.card
  WHERE active IS TRUE
    AND usr IN (
      SELECT id
      FROM actor.usr
      WHERE deleted IS FALSE
      AND home_ou IN (105,113,130,104,108,103,132,151,131,150,107,117)
  )
) to patron_barcode.csv delimiter ',' CSV header
-- COPY 77728

--patron settings

\copy (
  SELECT *
  FROM actor.usr_setting
  WHERE usr IN (
    SELECT id
    FROM actor.usr
    WHERE deleted IS FALSE
      AND home_ou IN (105,113,130,104,108,103,132,151,131,150,107,117)
  )
) to patron_setting.csv delimiter ',' CSV header
-- COPY 1297

--patron notes

\copy (
  SELECT *
  FROM actor.usr_note
  WHERE usr IN (
    SELECT id
    FROM actor.usr
    WHERE deleted IS FALSE
      AND home_ou IN (105,113,130,104,108,103,132,151,131,150,107,117)
  )
) to patron_notes.csv delimiter ',' CSV header
-- COPY 1987

--patron address

\copy (
  SELECT *
  FROM actor.usr_address
  WHERE usr IN (
    SELECT id
    FROM actor.usr
    WHERE deleted IS FALSE
    AND home_ou IN (105,113,130,104,108,103,132,151,131,150,107,117)
  )
) to patron_address.csv delimiter ',' CSV header
-- COPY 25395

--patron stat cats
\copy (
  SELECT m.target_usr, st.name,ste.value
  FROM actor.stat_cat st, actor.stat_cat_entry ste, actor.usr u, actor.stat_cat_entry_usr_map m
  WHERE u.id = m.target_usr
  AND u.deleted IS FALSE
  AND m.stat_cat = st.id
  AND m.stat_cat_entry = ste.value
  AND m.stat_cat = ste.stat_cat
  AND m.target_usr IN (
    SELECT id
    FROM actor.usr
    WHERE deleted IS FALSE
    AND home_ou IN (105,113,130,104,108,103,132,151,131,150,107,117)
  )
) to patron.stat_cat.csv delimiter ',' csv header
-- 19299

--patron bookbags

\copy (
  SELECT target_biblio_record_entry, barcode, name, title
  FROM container.biblio_record_entry_bucket c, container.biblio_record_entry_bucket_item i, reporter.super_simple_record r,actor.usr u, actor.card ca
  WHERE btype = 'bookbag'
    AND home_ou IN (105,113,130,104,108,103,132,151,131,150,107,117)
    AND c.id = i.bucket
    AND i.target_biblio_record_entry = r.id
    AND owner = u.id
    AND u.card = ca.id
    ORDER BY owner, name, title
) to patron_bookbags.csv delimiter ',' csv header
-- 30775

--export holds

--check for holds WHERE the pickup lib is not an algoma one
SELECT count(*) FROM action.hold_request WHERE request_lib IN (105,113,130,104,108,103,132,151,131,150,107,117) AND pickup_lib not IN (105,113,130,104,108,103,132,151,131,150,107,117) AND cancel_time IS NULL AND fulfillment_time IS NULL;
-- count 
---------
--     0
--(1 row)

conifer=# SELECT count(*) FROM action.hold_request WHERE request_lib IN (105,113,130,104,108,103,132,151,131,150,107,117) AND cancel_time IS NULL AND fulfillment_time IS NULL AND (expire_time > now() or expire_time IS NULL);
-- count 
---------
--    17

\copy (
  SELECT *
  FROM action.hold_request
  WHERE request_lib IN (105,113,130,104,108,103,132,151,131,150,107,117)
    AND cancel_time IS NULL
    AND fulfillment_time IS NULL
    AND (expire_time > now() or expire_time IS NULL)
) to hold.csv delimiter ',' CSV header
-- COPY 17

--export circ

\copy (
  SELECT *
  FROM action.circulation
  WHERE circ_lib IN (105,113,130,104,108,103,132,151,131,150,107,117)
  AND checkin_time IS NULL
) to circ.csv delimiter ',' CSV header
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
CREATE TABLE mlb.laurentian_fines AS SELECT * FROM money.billable_xact_summary_location_view  WHERE billing_location IN (105,113,130,104,108,103,132,151,131,150,107,117) AND balance_owed != 0 ORDER BY usr;
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
SET barcode =  co.barcode
FROM action.circulation ci, asset.copy co
WHERE a.id = ci.id
AND ci.target_copy = co.id ;
--UPDATE 4032


\copy (SELECT * FROM mlb.laurentian_fines ORDER BY usr) to fines.csv delimiter ',' CSV header
-- COPY 5377

--codes

--org units
\copy (SELECT * FROM actor.org_unit ORDER BY id) to org.csv delimiter ',' CSV header
-- COPY 49

--patron profile types
\copy (SELECT * FROM permission.grp_tree ORDER BY id) to patrontype.csv delimiter ',' CSV header
-- COPY 35

--item circ modifiers
\copy (SELECT * FROM config.circ_modifier ORDER BY code) to item_circ_modifiers.csv delimiter ',' CSV header
-- COPY 90

--item locations
\copy (SELECT * FROM asset.copy_location ORDER BY owning_lib, name) to item_location.csv delimiter ',' CSV header
-- COPY 815


--item status
\copy (SELECT * FROM config.copy_status) to item_status.csv delimiter ',' CSV header
-- COPY 20



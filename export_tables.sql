-- 1) export items

\copy (select co.*,ca.label,ca.label_class,ca.record,ou.name as libraryname,cl.name as copylocation,st.name as statusname from config.copy_status st,asset.copy co, asset.call_number ca, actor.org_unit ou, asset.copy_location cl where co.deleted is false and circ_lib in (105,113,130,104,108,103,132,151,131,150,107) and ca.deleted is false and ca.owning_lib in (105,113,130,104,108,103,132,151,131,150,107) and co.call_number = ca.id and co.circ_lib = ou.id and co.location = cl.id and co.status = st.id) to items.csv delimiter ',' CSV header

--item notes

\copy (select * from asset.copy_note where owning_copy in (select id from asset.copy where deleted is false and circ_lib in (105,113,130,104,108,103,132,151,131,150,107) and call_number in (select id from asset.call_number where deleted is false and owning_lib in (105,113,130,104,108,103,132,151,131,150,107)))) to item_notes.csv delimiter ',' CSV header
-- COPY 385

--item stat cats

\copy (select s.name,e.value,c.owning_copy from asset.stat_cat s, asset.stat_cat_entry e ,asset.stat_cat_entry_copy_map c where s.id = e.stat_cat and e.id = c.stat_cat_entry and c.owning_copy in (select id from asset.copy where deleted is false and circ_lib in (105,113,130,104,108,103,132,151,131,150,107) and call_number in (select id from asset.call_number where deleted is false and owning_lib in (105,113,130,104,108,103,132,151,131,150,107)))) to item_stats.csv delimiter ',' CSV header
-- COPY 29229

3) export the patron data

--patrons

\copy (select * from actor.usr where deleted is false and home_ou in (105,113,130,104,108,103,132,151,131,150,107)) to patron.csv delimiter ',' CSV header
-- COPY 77658

--patron barcodes
\copy (select * from actor.card where active is true and usr in (select id from actor.usr where deleted is false and home_ou in (105,113,130,104,108,103,132,151,131,150,107))) to patron_barcode.csv delimiter ',' CSV header
-- COPY 77728

--patron settings

\copy (select * from actor.usr_setting where usr in (select id from actor.usr where deleted is false and home_ou in (105,113,130,104,108,103,132,151,131,150,107))) to patron_setting.csv delimiter ',' CSV header
-- COPY 1297

--patron notes

\copy (select * from actor.usr_note where usr in (select id from actor.usr where deleted is false and home_ou in (105,113,130,104,108,103,132,151,131,150,107))) to patron_notes.csv delimiter ',' CSV header
-- COPY 1987

--patron address

\copy (select * from actor.usr_address where usr in (select id from actor.usr where deleted is false and home_ou in (105,113,130,104,108,103,132,151,131,150,107))) to patron_address.csv delimiter ',' CSV header
-- COPY 25395

--patron stat cats
\copy (select m.target_usr,st.name,ste.value from actor.stat_cat st ,actor.stat_cat_entry ste,actor.usr u, actor.stat_cat_entry_usr_map m where  u.id = m.target_usr and u.deleted is false and m.stat_cat = st.id and m.stat_cat_entry = ste.value and m.stat_cat = ste.stat_cat and m.target_usr in (select id from actor.usr where deleted is false and home_ou in (105,113,130,104,108,103,132,151,131,150,107))) to patron.stat_cat.csv delimiter ',' csv header
-- 19299

--patron bookbags

\copy (select target_biblio_record_entry,barcode,name,title from container.biblio_record_entry_bucket c, container.biblio_record_entry_bucket_item i, reporter.super_simple_record r,actor.usr u, actor.card ca where btype = 'bookbag' and home_ou in (105,113,130,104,108,103,132,151,131,150,107) and c.id = i.bucket and i.target_biblio_record_entry = r.id and owner = u.id and u.card = ca.id order by owner,name,title) to patron_bookbags.csv delimiter ',' csv header
-- 30775

--export holds

--check for holds where the pickup lib is not an algoma one
select count(*) from action.hold_request where request_lib in (105,113,130,104,108,103,132,151,131,150,107) and pickup_lib not in (105,113,130,104,108,103,132,151,131,150,107) and cancel_time is null and fulfillment_time is null;
-- count 
---------
--     0
--(1 row)

conifer=# select count(*) from action.hold_request where request_lib in (105,113,130,104,108,103,132,151,131,150,107) and cancel_time is null and fulfillment_time is null and (expire_time > now() or expire_time is null);
-- count 
---------
--    17

\copy (select * from action.hold_request where request_lib in (105,113,130,104,108,103,132,151,131,150,107) and cancel_time is null and fulfillment_time is null and (expire_time > now() or expire_time is null)) to hold.csv delimiter ',' CSV header
-- COPY 17

--export circ

\copy (select * from action.circulation where circ_lib in (105,113,130,104,108,103,132,151,131,150,107) and checkin_time is null) to circ.csv delimiter ',' CSV header
-- COPY 3398

--fines

select count(*) from money.billable_xact_summary_location_view  where billing_location in (105,113,130,104,108,103,132,151,131,150,107) and balance_owed  != 0 ;
-- count 
---------
--  5381
--(1 row)

select count(distinct usr) from money.billable_xact_summary_location_view  where billing_location in (105,113,130,104,108,103,132,151,131,150,107) and balance_owed != 0 ;
--  count 
-- -------
--    2338

drop table mlb.laurentian_fines;
create table mlb.laurentian_fines as select * from money.billable_xact_summary_location_view  where billing_location in (105,113,130,104,108,103,132,151,131,150,107) and balance_owed != 0 order by usr;
-- SELECT 5377

alter table mlb.laurentian_fines add column title text;
alter table mlb.laurentian_fines add column barcode text;
--grab title 
update mlb.laurentian_fines a set title =  r.title from reporter.super_simple_record r, action.circulation ci, asset.copy co, asset.call_number ca where a.id = ci.id and ci.target_copy = co.id and co.call_number = ca.id and ca.record = r.id;
-- UPDATE 4032

update mlb.laurentian_fines a set barcode =  co.barcode from action.circulation ci, asset.copy co where a.id = ci.id and ci.target_copy = co.id ;
--UPDATE 4032


\copy (select * from mlb.laurentian_fines order by usr) to fines.csv delimiter ',' CSV header
-- COPY 5377

--codes

--org units
\copy (select * from actor.org_unit order by id) to org.csv delimiter ',' CSV header
-- COPY 49

--patron profile types
\copy (select * from permission.grp_tree order by id) to patrontype.csv delimiter ',' CSV header
-- COPY 35

--item circ modifiers
\copy (select * from config.circ_modifier order by code) to item_circ_modifiers.csv delimiter ',' CSV header
-- COPY 90

--item locations
\copy (select * from asset.copy_location order by owning_lib, name) to item_location.csv delimiter ',' CSV header
-- COPY 815


--item status
\copy (select * from config.copy_status) to item_status.csv delimiter ',' CSV header
-- COPY 20



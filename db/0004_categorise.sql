-- ===========================================================================
-- Give every product a category.
-- ===========================================================================
-- Paste into the Supabase SQL editor and Run. Safe to re-run.
--
-- Fourteen of the twenty-four seeded products arrived with no tags, so the
-- seed's tag-to-category pass left them with a null category_id. That made
-- them invisible to the home screen's collections and to every category tile
-- - the catalogue looked two thirds empty while the rows were sitting there.
--
-- The seed itself now assigns these (db/build_seed.py), but its inserts are
-- ON CONFLICT DO NOTHING and will not touch rows that already exist, which is
-- why this file exists separately.
-- ===========================================================================

update products p set category_id = v.cat
from (values
  -- Boubou Wax Royal
  ('b2506a20-529f-5fa7-91c1-a52e0ee92985'::uuid, 'e42b3238-5882-54cd-b265-644d74f627ed'::uuid),
  -- Ensemble Ankara
  ('e8a36cf1-305d-5aee-bfbd-27b964965687'::uuid, '12952e63-8808-5a67-9b3b-da33c924ddf3'::uuid),
  -- Tunique Kente
  ('68b5b753-282e-5112-8f7d-32de4999e9fb'::uuid, 'aaab66ad-9f1f-5dd2-a27d-6038de667920'::uuid),
  -- Sac Raphia Tressé
  ('424c160d-4f81-573b-b917-0eccea936cf0'::uuid, 'fb85fe42-14f4-5064-b1aa-054bcf083fe0'::uuid),
  -- Sandales Cuir Bio
  ('83d7b911-241a-5d91-be2c-f46d8fc91063'::uuid, '844b0adf-7c7f-5447-9e60-434868f9f7ab'::uuid),
  -- Boucles Cauri Gold
  ('c8be2539-4404-5209-957e-23d14ce58270'::uuid, 'a730dda2-4798-5691-ab1c-6d679a109b85'::uuid),
  -- Chemise Bogolan
  ('dd861805-fd37-5181-bc49-74fe2d3f4806'::uuid, 'dd41565b-7594-596d-bba3-d21adf8927ae'::uuid),
  -- Tableau Batik
  ('e7a764e8-1957-5320-873a-faa95d216312'::uuid, 'aaab66ad-9f1f-5dd2-a27d-6038de667920'::uuid),
  -- Poupée Akan
  ('1f5ba491-561b-5463-b579-b6c880829d3b'::uuid, 'aaab66ad-9f1f-5dd2-a27d-6038de667920'::uuid),
  -- Robe Indigo
  ('74565403-d868-5699-b158-b1b9d3fd3d3a'::uuid, 'e42b3238-5882-54cd-b265-644d74f627ed'::uuid),
  -- Veste Bogolan
  ('2f92b189-69c2-5ddf-aa9c-4c83f9039814'::uuid, '12952e63-8808-5a67-9b3b-da33c924ddf3'::uuid),
  -- Jupe Plissée Wax
  ('28f79ab3-8ecc-5ab4-b5be-6d736afc0aba'::uuid, 'e42b3238-5882-54cd-b265-644d74f627ed'::uuid),
  -- Panier Osier
  ('a2081627-f06b-5790-b218-2f67679e59e1'::uuid, 'fb85fe42-14f4-5064-b1aa-054bcf083fe0'::uuid),
  -- Ceinture Jute
  ('fddfdbd8-4c35-59df-a927-de96429d11df'::uuid, 'fefed0d2-10e5-5782-91e0-dcb1223c20de'::uuid),
  -- Tote Bag Coton
  ('4052f22a-009d-5468-b416-485c335c39d4'::uuid, 'fefed0d2-10e5-5782-91e0-dcb1223c20de'::uuid),
  -- Pochette Sisal
  ('6d560a3c-3efd-5aca-b6d6-78821ce7460e'::uuid, 'fb85fe42-14f4-5064-b1aa-054bcf083fe0'::uuid),
  -- Masque Sculpté
  ('d57638eb-27dd-57ca-86d2-e0a483259c05'::uuid, 'aaab66ad-9f1f-5dd2-a27d-6038de667920'::uuid),
  -- Écharpe Soie Sauvage
  ('6d6b0476-7b04-51af-a31e-9d12d50eba31'::uuid, '12952e63-8808-5a67-9b3b-da33c924ddf3'::uuid),
  -- Bougie Parfumée
  ('c24cd83a-7492-54ad-83bc-f65239a58f58'::uuid, 'dd41565b-7594-596d-bba3-d21adf8927ae'::uuid),
  -- Coffret Épices
  ('a3582eb8-913c-5a56-94cf-8da7b4536892'::uuid, 'dd41565b-7594-596d-bba3-d21adf8927ae'::uuid),
  -- Tissage Traditionnel
  ('fbf163e7-c3f2-5a75-b018-6414eb50973f'::uuid, 'aaab66ad-9f1f-5dd2-a27d-6038de667920'::uuid),
  -- Potterie Artisanale
  ('91c034eb-01e5-5d1f-925f-9cbee7796147'::uuid, 'aaab66ad-9f1f-5dd2-a27d-6038de667920'::uuid),
  -- Vase Céramique
  ('06b535e1-676e-5f0e-bf5f-3f8e0d83eb6e'::uuid, 'aaab66ad-9f1f-5dd2-a27d-6038de667920'::uuid),
  -- Statue Bronze
  ('84919b3f-9e4c-54c4-89ef-92637c7e4bee'::uuid, 'aaab66ad-9f1f-5dd2-a27d-6038de667920'::uuid)
) as v(id, cat)
where p.id = v.id and p.category_id is distinct from v.cat;

-- Check: this should come back empty.
--   select name from products where category_id is null;

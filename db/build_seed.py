#!/usr/bin/env python3
"""Generate db/0002_seed.sql from supabase_init/*.json.

Generated rather than hand-written because the JSON is the source the designer
and the founder actually edit, and a seed transcribed by hand drifts from it
silently. Re-run after changing any of those files.

Ids are uuid5 over the slug, so the seed is idempotent: running it twice
produces the same ids and the ON CONFLICT clauses make the second run a no-op.
A random uuid would create a parallel duplicate catalogue on every run.
"""

import json
import pathlib
import re
import uuid

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / "supabase_init"
OUT = ROOT / "db" / "0002_seed.sql"

# Any fixed namespace works; it only has to stay the same between runs.
NS = uuid.UUID("afa05ee2-0000-4000-8000-000000000001")


def uid(kind: str, key: str) -> str:
    return str(uuid.uuid5(NS, f"afrostand:{kind}:{key}"))


def slugify(name: str) -> str:
    s = name.lower()
    for a, b in [("à", "a"), ("â", "a"), ("ä", "a"), ("é", "e"), ("è", "e"),
                 ("ê", "e"), ("ë", "e"), ("î", "i"), ("ï", "i"), ("ô", "o"),
                 ("ö", "o"), ("ù", "u"), ("û", "u"), ("ü", "u"), ("ç", "c")]:
        s = s.replace(a, b)
    s = re.sub(r"[^a-z0-9]+", "-", s).strip("-")
    return s or "item"


def q(v) -> str:
    """SQL literal. Doubling the quote is the whole escaping story here, and the
    input is a repo file rather than user input, but names like "Aïsha K." and
    "L'Atelier" are exactly the kind of thing that breaks a naive generator."""
    if v is None:
        return "null"
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, (int, float)):
        return str(v)
    return "'" + str(v).replace("'", "''") + "'"


def arr(values) -> str:
    if not values:
        return "'{}'"
    return "array[" + ", ".join(q(v) for v in values) + "]::text[]"


def main() -> None:
    cats = json.loads((SRC / "categories.json").read_text(encoding="utf-8"))
    creators = json.loads((SRC / "creators.json").read_text(encoding="utf-8"))
    prods = json.loads((SRC / "products.json").read_text(encoding="utf-8"))

    cat_by_slug = {c["slug"]: uid("category", c["slug"]) for c in cats}
    cat_slugs = set(cat_by_slug)

    # The tags are French, several of the category slugs are English. "Cadeau"
    # and "gift" are the same shelf, and without this a third of the catalogue
    # sits in no category at all.
    ALIAS = {"cadeau": "gift", "habits": "local", "accessoire": "local"}
    creator_by_name = {c["name"]: uid("creator", slugify(c["name"])) for c in creators}

    out = [
        "-- ===========================================================================",
        "-- AFROSTAND seed - GENERATED, do not edit.",
        "-- Source: supabase_init/{categories,creators,products}.json",
        "-- Regenerate: python3 db/build_seed.py",
        "-- ===========================================================================",
        "-- Ids are uuid5 over the slug, so this is safe to re-run: the same rows get",
        "-- the same ids and ON CONFLICT turns a second run into a no-op rather than a",
        "-- duplicate catalogue.",
        "--",
        "-- These creators have no profile_id. They are the shops the marketplace",
        "-- launches with, not accounts - a real person claims one later by having",
        "-- profile_id set. Until then nobody can edit their products, because",
        "-- my_creator_id() can never return their id.",
        "",
    ]

    out.append("-- categories")
    for i, c in enumerate(cats):
        out.append(
            "insert into categories (id, name, slug, image_url, description, sort) values "
            f"({q(cat_by_slug[c['slug']])}, {q(c['name'])}, {q(c['slug'])}, "
            f"{q(c.get('image_url'))}, {q(c.get('description'))}, {i}) "
            "on conflict (id) do nothing;"
        )

    out.append("")
    out.append("-- creators")
    for c in creators:
        slug = slugify(c["name"])
        out.append(
            "insert into creators (id, name, slug, is_approved) values "
            f"({q(creator_by_name[c['name']])}, {q(c['name'])}, {q(slug)}, true) "
            "on conflict (id) do nothing;"
        )

    out.append("")
    out.append("-- products")
    unmatched = 0
    for p in prods:
        pid = uid("product", slugify(p["creator"]) + "/" + slugify(p["name"]))
        # First tag that is also a category slug wins. Products whose tags name
        # no category keep a null category and are still reachable by tag.
        cat = None
        for t in p.get("tags", []):
            slug = ALIAS.get(slugify(t), slugify(t))
            if slug in cat_slugs:
                cat = cat_by_slug[slug]
                break
        if cat is None:
            unmatched += 1
        disc = p.get("discount")
        if isinstance(disc, str):
            m = re.search(r"\d+", disc)
            disc = int(m.group()) if m else None
        out.append(
            "insert into products (id, creator_id, category_id, name, price_xaf, "
            "discount_pct, image_url, tags, is_new) values ("
            f"{q(pid)}, {q(creator_by_name[p['creator']])}, {q(cat)}, {q(p['name'])}, "
            f"{int(p['price'])}, {q(disc)}, {q(p['image_url'])}, {arr(p.get('tags'))}, "
            f"{q(bool(p.get('is_new', False)))}) on conflict (id) do nothing;"
        )

    # Posts, so the feed is not empty on a fresh install. Each one is a real
    # shop showing a real product it actually sells - the same relationship a
    # genuine post would have. Not invented content: the caption is the product
    # name and the image is the product's own.
    out.append("")
    out.append("-- posts: each seeded shop showing one of its own products")
    seen = set()
    for pr in prods:
        if pr["creator"] in seen:
            continue
        seen.add(pr["creator"])
        pid = uid("product", slugify(pr["creator"]) + "/" + slugify(pr["name"]))
        out.append(
            "insert into posts (id, creator_id, product_id, image_url, caption) values ("
            f"{q(uid('post', slugify(pr['creator']) + '/' + slugify(pr['name'])))}, "
            f"{q(creator_by_name[pr['creator']])}, {q(pid)}, {q(pr['image_url'])}, "
            f"{q(pr['name'])}) on conflict (id) do nothing;"
        )

    OUT.write_text("\n".join(out) + "\n", encoding="utf-8")
    print(
        f"wrote {OUT.relative_to(ROOT)} - "
        f"{len(cats)} categories, {len(creators)} creators, {len(prods)} products "
        f"({unmatched} with no category), {len(seen)} posts"
    )


if __name__ == "__main__":
    main()

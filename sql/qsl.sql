create table qslimage (
    qslid integer primary key generated always as identity,
    width integer,
    height integer,
    twidth integer,
    theight integer,
    replied boolean,
    image bytea,
    thumbnail bytea
);

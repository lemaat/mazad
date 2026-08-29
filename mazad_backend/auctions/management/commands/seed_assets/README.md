# MAZAD seed listing images

8 real photos, sourced by the user from pexels.com (Pexels license — free to use,
no attribution required: https://www.pexels.com/license/), resized to a max
900px edge and re-compressed as JPEG for a small repo footprint (~40-120KB each,
512KB total).

Drop this folder into `mazad_backend/auctions/management/commands/seed_assets/`
(as `cars/`, `land/`, `goods/` subfolders) and point `_seed_listing_images()`
at real files with `open(path, 'rb')` instead of the generated 1x1 PNGs.

- `cars/honda_civic.jpg` — silver Honda Civic, front 3/4, forest road.
- `land/aerial_plot.jpg` — aerial view of a hillside plot with a dirt track, red-earth farmland.
- `land/house_property.jpg` — brick/sided house exterior with yard, driveway, blue sky.
- `goods/guitar.jpg` — close-up acoustic guitar body/neck.
- `goods/sofa.jpg` — gray sectional sofa with ottoman, modern living room.
- `goods/bistro_table_chairs.jpg` — yellow folding bistro table + 4 chairs, outdoor cafe.
- `goods/laptop.jpg` — HP laptop open on a desk, classroom setting.
- `goods/hotel_beds.jpg` — twin beds with wall decor, hotel-style bedroom.

Land only has 2 images and Goods has 5 — reuse images across multiple seeded
listings within the same category rather than requiring a 1:1 image-per-listing
match; that's fine for demo purposes since the goal is "real photo, not a
placeholder swatch," not a literal match to each listing's title.

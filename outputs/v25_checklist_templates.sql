-- v25: Checklist templates — editable, reusable starter checklists
-- Run this once in the Supabase SQL editor. Adds two tables (mirroring the
-- rs_checklists/rs_checklist_items shape) plus seed data: the existing
-- Website Checklist (moved out of the hardcoded WEBSITE_CHECKLIST_TEMPLATE
-- JS constant, which is removed from index.html now that this is the source
-- of truth) plus three new templates — Branding, Animation/Video, and
-- Deck/Presentation — covering the other project types this team delivers.
-- Manage templates and their tasks from Settings > "Checklist templates".

create table if not exists rs_checklist_templates (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  position int not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists rs_checklist_template_items (
  id uuid primary key default gen_random_uuid(),
  template_id uuid not null references rs_checklist_templates(id) on delete cascade,
  category text,
  label text not null,
  detail text,
  position int not null default 0,
  created_at timestamptz not null default now()
);

-- Supabase now enables RLS by default on tables created via the SQL editor;
-- every other table in this app has RLS off so the anon key can read/write
-- freely (see CLAUDE.md) — match that here from the start this time.
alter table rs_checklist_templates disable row level security;
alter table rs_checklist_template_items disable row level security;

-- ---------- Website Checklist (50 items, migrated verbatim) ----------
with tpl as (
  insert into rs_checklist_templates (name, position) values ('Website Checklist', 0) returning id
)
insert into rs_checklist_template_items (template_id, category, label, detail, position)
select tpl.id, v.category, v.label, v.detail, v.position from tpl, (values
  ('Copy & Content','All placeholder text removed','No Lorem Ipsum, TBD, [CLIENT NAME], or template copy',0),
  ('Copy & Content','Headlines and body copy proofread','Spelling, grammar, punctuation checked',1),
  ('Copy & Content','Client name and product names spelled correctly','Check every instance across all pages',2),
  ('Copy & Content','All CTAs are correctly labelled','Button text makes sense in context',3),
  ('Copy & Content','Meta title and description filled in','Every page has unique, accurate meta copy',4),
  ('Copy & Content','Legal / compliance copy present','Privacy policy, cookie notice, disclaimers if required',5),
  ('Links & Navigation','All navigation links work','Desktop and mobile nav tested end-to-end',6),
  ('Links & Navigation','No broken internal links','Click through every page link',7),
  ('Links & Navigation','External links open correctly','Check target (new tab where expected)',8),
  ('Links & Navigation','Footer links all work','Including social links and legal pages',9),
  ('Links & Navigation','Logo links to homepage','Standard expectation, easy to miss',10),
  ('Links & Navigation','404 page is styled','Custom 404 or sensible fallback in place',11),
  ('Visual & Brand','Brand colours match approved palette','No off-hex values slipping through',12),
  ('Visual & Brand','Typography matches design spec','Fonts, weights, sizes, line-heights',13),
  ('Visual & Brand','All images load correctly','No broken images, no placeholder images',14),
  ('Visual & Brand','Images are appropriately sized and sharp','Retina images for 2x displays where needed',15),
  ('Visual & Brand','Favicon is set','Browser tab icon is correct, not default',16),
  ('Visual & Brand','Logo appears correctly across all pages','Correct file, correct sizing',17),
  ('Visual & Brand','Spacing and alignment consistent','No rogue padding/margin from CMS or overrides',18),
  ('Visual & Brand','Animations play correctly','Scroll animations, Lottie, video — tested on reload',19),
  ('Responsive & Cross-Browser','Tested on mobile (iOS Safari)','Most common edge-case browser',20),
  ('Responsive & Cross-Browser','Tested on mobile (Android Chrome)',null,21),
  ('Responsive & Cross-Browser','Tested on desktop Chrome',null,22),
  ('Responsive & Cross-Browser','Tested on desktop Safari','Especially for CSS features and fonts',23),
  ('Responsive & Cross-Browser','Tested on desktop Firefox',null,24),
  ('Responsive & Cross-Browser','No horizontal scroll on mobile','Check at 320px, 375px, 390px viewports',25),
  ('Responsive & Cross-Browser','Tap targets large enough on mobile','Min 44×44px for interactive elements',26),
  ('Responsive & Cross-Browser','Hamburger / mobile nav works','Opens, closes, all links accessible',27),
  ('Forms & Interactions','All forms submit correctly','Test with valid and invalid data',28),
  ('Forms & Interactions','Form validation messages appear','Required fields, format validation',29),
  ('Forms & Interactions','Success states show after submission','Confirmation message or redirect works',30),
  ('Forms & Interactions','Form submissions reach the right inbox','Send a test submission and confirm receipt',31),
  ('Forms & Interactions','reCAPTCHA or spam protection active','If applicable',32),
  ('Performance & Technical','No console errors in DevTools','Open F12 → Console on all pages',33),
  ('Performance & Technical','Page load feels fast','Run Lighthouse or PageSpeed Insights',34),
  ('Performance & Technical','SSL certificate active (HTTPS)','Padlock shows in browser',35),
  ('Performance & Technical','Redirects working correctly','www → non-www or vice versa, old URLs if migrated',36),
  ('Performance & Technical','Analytics tracking confirmed','GA4, Mixpanel or similar firing correctly',37),
  ('Performance & Technical','Cookie consent banner working','If required for region/client',38),
  ('Performance & Technical','No staging/test domain references','Check OG tags, canonical tags, sitemaps',39),
  ('Accessibility Basics','Images have alt text','Descriptive alt for content images, empty for decorative',40),
  ('Accessibility Basics','Colour contrast is sufficient','Body text WCAG AA: min 4.5:1 ratio',41),
  ('Accessibility Basics','Keyboard navigation works','Tab through the page — focus states visible',42),
  ('Accessibility Basics','Page has a logical heading structure','One H1, logical H2/H3 hierarchy',43),
  ('Accessibility Basics','Animations respect prefers-reduced-motion','Or a pause control is available',44),
  ('Client Handover','CMS login details prepared','Or agreed handover method',45),
  ('Client Handover','Domain / DNS notes documented','Any custom config the client needs to know',46),
  ('Client Handover','Staging password removed','Client shouldn''t hit a password wall',47),
  ('Client Handover','Browser tab title correct on all pages','Not "Home | Framer" or similar default',48),
  ('Client Handover','Social share image (OG image) set','Test with opengraph.xyz',49)
) as v(category, label, detail, position);

-- ---------- Branding Checklist ----------
with tpl as (
  insert into rs_checklist_templates (name, position) values ('Branding Checklist', 1) returning id
)
insert into rs_checklist_template_items (template_id, category, label, detail, position)
select tpl.id, v.category, v.label, v.detail, v.position from tpl, (values
  ('Strategy & Concept','Brand direction approved by client before final art','Avoids reworking finished assets',0),
  ('Strategy & Concept','Mood board / references match agreed direction',null,1),
  ('Strategy & Concept','Naming cleared for conflicts','If naming was part of scope',2),
  ('Strategy & Concept','Tagline / positioning line signed off',null,3),
  ('Logo & Marks','Primary logo finalised in vector format',null,4),
  ('Logo & Marks','Secondary / submark variations complete','Icon, wordmark, stacked lockup',5),
  ('Logo & Marks','Logo scales cleanly at favicon size','16–32px without losing legibility',6),
  ('Logo & Marks','Clear space and minimum size rules defined',null,7),
  ('Logo & Marks','Logo tested on light and dark backgrounds',null,8),
  ('Logo & Marks','Logo tested on brand''s primary colour backgrounds',null,9),
  ('Logo & Marks','Incorrect usage examples documented','Stretching, recolouring, low contrast, etc.',10),
  ('Colour & Typography','Primary and secondary palette finalised','Hex, RGB, CMYK and Pantone values recorded',11),
  ('Colour & Typography','Colour contrast checked on key pairings',null,12),
  ('Colour & Typography','Typefaces licensed for client''s intended use',null,13),
  ('Colour & Typography','Type scale documented','Headings, body, captions',14),
  ('Colour & Typography','Web-safe font fallbacks specified',null,15),
  ('Applications & Mockups','Business card / stationery mockups approved',null,16),
  ('Applications & Mockups','Social profile and cover assets sized per platform',null,17),
  ('Applications & Mockups','Letterhead / email signature template created',null,18),
  ('Applications & Mockups','Signage or merch mockups reviewed','If in scope',19),
  ('Applications & Mockups','Mockups shown in realistic context','Not just flat logo lockups',20),
  ('File Delivery','Final logo exported in AI / EPS (vector)',null,21),
  ('File Delivery','PNG exports with transparent background','Multiple sizes',22),
  ('File Delivery','JPG exports for print / general use',null,23),
  ('File Delivery','SVG exported and tested in browser',null,24),
  ('File Delivery','Favicon package generated','.ico plus PNG sizes',25),
  ('File Delivery','Files organised into a clearly labelled folder structure',null,26),
  ('Brand Guidelines','Brand guidelines document created / updated',null,27),
  ('Brand Guidelines','Guidelines cover logo, colour, type, imagery style',null,28),
  ('Brand Guidelines','Guidelines checked against final delivered assets',null,29),
  ('Brand Guidelines','PDF export tested for correct rendering / embedded fonts',null,30),
  ('Client Handover','Source files shared or archived per contract','AI / PSD / Figma',31),
  ('Client Handover','Client informed of font licensing terms','Including renewal if applicable',32),
  ('Client Handover','Handover call or summary completed',null,33),
  ('Client Handover','Feedback and sign-off documented in writing',null,34)
) as v(category, label, detail, position);

-- ---------- Animation / Video Checklist ----------
with tpl as (
  insert into rs_checklist_templates (name, position) values ('Animation / Video Checklist', 2) returning id
)
insert into rs_checklist_template_items (template_id, category, label, detail, position)
select tpl.id, v.category, v.label, v.detail, v.position from tpl, (values
  ('Pre-Production','Brief and objectives confirmed with client',null,0),
  ('Pre-Production','Reference / mood board approved',null,1),
  ('Pre-Production','Runtime agreed and documented',null,2),
  ('Pre-Production','Aspect ratio and platform destination confirmed','16:9, 1:1, 9:16, etc.',3),
  ('Storyboard & Script','Script / voiceover copy approved',null,4),
  ('Storyboard & Script','Storyboard covers every beat with timing notes',null,5),
  ('Storyboard & Script','Storyboard signed off before animation begins',null,6),
  ('Design & Style Frames','Style frames match brand guidelines','Colour, type, illustration style',7),
  ('Design & Style Frames','Style frames approved before full animation starts',null,8),
  ('Design & Style Frames','Character / asset designs consistent across frames',null,9),
  ('Animation & Motion','Motion feels consistent with brand tone','Pace, easing',10),
  ('Animation & Motion','No jittery or broken keyframes',null,11),
  ('Animation & Motion','Transitions between scenes are smooth',null,12),
  ('Animation & Motion','On-screen text is legible and on-brand',null,13),
  ('Animation & Motion','Safe zones respected for text and logo','Won''t be cropped on any target platform',14),
  ('Animation & Motion','Loop point is seamless','If the animation loops',15),
  ('Audio & Sound','Voiceover synced correctly to visuals',null,16),
  ('Audio & Sound','Music licensed for intended use',null,17),
  ('Audio & Sound','Sound effects timed to match action',null,18),
  ('Audio & Sound','Audio levels balanced','No clipping, consistent loudness',19),
  ('Audio & Sound','Final mix checked on headphones and speakers',null,20),
  ('Export & Delivery','Exported at correct resolution','1080p / 4K as agreed',21),
  ('Export & Delivery','Correct frame rate for platform',null,22),
  ('Export & Delivery','File format matches requirements','MP4, MOV, GIF, etc.',23),
  ('Export & Delivery','Captions / subtitles delivered if required','Burned in or as a separate file',24),
  ('Export & Delivery','Alternate cuts delivered if requested','15s / 30s / square / vertical',25),
  ('Export & Delivery','Source project files archived',null,26),
  ('Client Review','Review link shared with correct access',null,27),
  ('Client Review','Feedback rounds tracked against agreed revisions',null,28),
  ('Client Review','Final approval received in writing before final render',null,29),
  ('Client Review','Delivered files tested by playing before sending',null,30)
) as v(category, label, detail, position);

-- ---------- Deck / Presentation Checklist ----------
with tpl as (
  insert into rs_checklist_templates (name, position) values ('Deck / Presentation Checklist', 3) returning id
)
insert into rs_checklist_template_items (template_id, category, label, detail, position)
select tpl.id, v.category, v.label, v.detail, v.position from tpl, (values
  ('Content & Structure','Narrative flow makes sense start to finish',null,0),
  ('Content & Structure','Structure matches client''s requested outline',null,1),
  ('Content & Structure','Slide count matches agreed scope',null,2),
  ('Content & Structure','Speaker notes added where needed',null,3),
  ('Data & Accuracy','All numbers and stats double-checked against source',null,4),
  ('Data & Accuracy','Charts and graphs labelled correctly','Axes, units, legend',5),
  ('Data & Accuracy','Client name and details correct throughout',null,6),
  ('Data & Accuracy','No outdated or placeholder figures remain',null,7),
  ('Visual & Brand','Brand colours and fonts used consistently',null,8),
  ('Visual & Brand','Logo placement consistent across all slides',null,9),
  ('Visual & Brand','Imagery is high resolution, not pixelated',null,10),
  ('Visual & Brand','Icon style consistent throughout',null,11),
  ('Slide Craft','Consistent alignment and spacing across slides',null,12),
  ('Slide Craft','Text doesn''t overflow placeholders or get cut off',null,13),
  ('Slide Craft','Consistent slide numbering / footer',null,14),
  ('Slide Craft','Transitions and animations are subtle and consistent','If used',15),
  ('Slide Craft','Proofread pass done — no typos or grammar issues',null,16),
  ('Technical & Export','Fonts embedded or outlined for PDF export',null,17),
  ('Technical & Export','Tested in the actual presentation software','PowerPoint, Keynote, or Google Slides',18),
  ('Technical & Export','Exported PDF checked for correct rendering',null,19),
  ('Technical & Export','File size reasonable for email / sharing',null,20),
  ('Technical & Export','Embedded animations / video tested and play correctly',null,21),
  ('Client Handover','Editable source file delivered per contract',null,22),
  ('Client Handover','Correct file format(s) delivered','PPTX, KEY, PDF',23),
  ('Client Handover','Delivery method confirmed','Email, shared drive, etc.',24),
  ('Client Handover','Final sign-off received from client',null,25)
) as v(category, label, detail, position);

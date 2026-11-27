# To rewrite

Files of the 4.x bundles still written the old way (3.1). They are **not built** and **not used**: they are kept
here only as a reference of what is left to rewrite.

Each file keeps the path it had in its bundle: `to-rewrite/<bundle>/<path in the bundle>`.

When a file is rewritten (module system: `@use` of `styles/mixin/*` and `styles/config/*`, like
`components/modal/modal.scss`), its new version goes into its bundle and the file is deleted from here.

## design-bundle

### Styles of the administration (3.1 global mixins of `_legacy.scss`)

Target once rewritten: `admin-bundle/src/Resources/assets/styles/admin/`.

- `src/Resources/assets/styles/admin/_index.scss`
- `src/Resources/assets/styles/admin/_legacy.scss` (variables, mixins, fonts and colors of 3.1)
- `src/Resources/assets/styles/admin/layout/`: `_body.scss`, `_login.scss`, `_navigation.scss`
- `src/Resources/assets/styles/admin/components/`: `_avatar.scss`, `_bandeau-top.scss`, `_configuration.scss`,
  `_dashboard.scss`, `_helper.scss`, `_list.scss`, `_svg.scss`, `_sweetAlert.scss`, `_table.scss`, `_tile.scss`,
  `_title.scss`
- `src/Resources/assets/styles/admin/components/symfonyFields/`: `_country.scss`, `_currency.scss`,
  `_dateTime.scss`, `_money.scss`

### Styles of design-bundle components

Target once rewritten: the same path in design-bundle, then added to `components/_index.scss` (or to the
`_index.scss` of the field). Their JS is already rewritten and stays in design-bundle.

- `src/Resources/assets/components/aside/_aside.scss`
- `src/Resources/assets/components/collapse/_collapse.scss`
- `src/Resources/assets/components/multi-user/_multi-user.scss`
- `src/Resources/assets/components/tab/_tab.scss`
- `src/Resources/assets/components/toast/_toast.scss`
- `src/Resources/assets/components/toggle/_toggle.scss`
- `src/Resources/assets/components/guideline/_guideline.scss`
- `src/Resources/assets/components/guideline/_guideline-components.scss`
- `src/Resources/assets/components/form/fields/input/_counter.scss` (`@forward "counter"` in `input/_index.scss`)
- `src/Resources/assets/components/form/fields/textarea/wysiwyg/_wysiwyg.scss`
  (`@forward "wysiwyg/wysiwyg"` in `textarea/_index.scss`)

### Mixins of 3.1 without an equivalent of the same name in `styles/mixin/`

`flex-display`, `flex-direction`, `flex-wrap`, `grid-column-gap`, `transitions-default`: to replace by the mixins
of `styles/mixin/_flex.scss` / `_grid.scss` (parameters and output to check).

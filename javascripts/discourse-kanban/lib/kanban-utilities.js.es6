const categorySetting = (type, slug, allowTopRoutes = true) => {
  if (!slug && !allowTopRoutes) return false;
  const categories = settings[type].split("|");
  const lookup = slug || "@";
  return categories.includes(lookup);
}

const displayConnector = (categorySlug) => {
  return settings.display_categories === "" ||
    categorySetting('display_categories', categorySlug);
}

const boardDefaultView = (categorySlug) => {
  return categorySetting('default_view', categorySlug, false);
}

const isDefaultView = (transition) => {
  let path = transition.intent.url || window.location.pathname;
  return path.indexOf('/l/') === -1;
}

export { displayConnector, boardDefaultView, isDefaultView }
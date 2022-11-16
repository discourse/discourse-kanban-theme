const categorySetting = (type, slug, allowTopRoutes = true) => {
  if (!slug && !allowTopRoutes) {
    return false;
  }
  const categories = settings[type].split("|");
  // console.log("CATE：");
  // console.log(categories);
  const lookup = slug || "@";
  // console.log("SLUG:");
  // console.log(slug);
  return categories.includes(lookup);
};

const getCurrentCategoryUrl = () => {
  let categorySlug = window.location.href.split("/")[4];
  const subcate = window.location.href.split("/")[5];
  if (typeof(subcate) == 'string')
    if (isNaN(Number(subcate)) && subcate.length != 1)
      categorySlug = subcate;
  if (categorySlug == undefined) categorySlug = '@';
  return categorySlug;
}

const displayConnector = (categorySlug) => {
  return (
    settings.display_categories === "" ||
    categorySetting("display_categories", categorySlug)
  );
};

const boardDefaultView = (categorySlug) => {
  categorySlug = getCurrentCategoryUrl();
  return categorySetting("default_view", categorySlug, false);
};

const isDefaultView = (transition) => {
  return transition.to.name === "discovery.category";
};

export { displayConnector, boardDefaultView, isDefaultView, getCurrentCategoryUrl };

const getCurrentCategoryFromUrl = () => {
  // Alternate solution: When the categorySlug is not obtained correctly, bypass the wrong categorySlug through the URL
  // In general we assume that url of a category has the structure of 
  // https://yourwebsite.com/c/categorySlug/subcategorySlug/subsubcateSlug/...
  // The following code relies heavily on '/c/' in the URL
  const splitURL = window.location.href.split('/');
  const numForCategory = splitURL.indexOf('c');
  
  // You can't find '/c/' in the url in the top level view...
  if (numForCategory == -1) return '@';
  
  let categorySlug = splitURL[numForCategory + 1];
  const subcateSlug = splitURL[numForCategory + 2];
  const subsubcateSlug = splitURL[numForCategory + 3];
  
  // What needs special attention is that if the following judgments are not made, the code will mistakenly think that something like 'l' or '101' is the name of the category
  if (typeof(subcateSlug) == 'string')
    if (isNaN(Number(subcateSlug)) && subcateSlug.length != 1)
      categorySlug = subcateSlug;
  if (typeof(subsubcateSlug) == 'string')
    if (isNaN(Number(subsubcateSlug)) && subsubcateSlug.length != 1)
      categorySlug = subsubcateSlug;

  return categorySlug;
}

const categorySetting = (type, slug, allowTopRoutes = true) => {
  if (!slug && !allowTopRoutes) {
    return false;
  }
  const categories = settings[type].split("|");
  const lookup = slug || "@";
  return categories.includes(lookup);
};

const displayConnector = (categorySlug) => {
  return (
    settings.display_categories === "" ||
    categorySetting("display_categories", categorySlug)
  );
};

const boardDefaultView = (categorySlug) => {
  // When the categorySlug is undefined, bypass the wrong categorySlug through the URL
  categorySlug = categorySlug || getCurrentCategoryFromUrl();
  return categorySetting("default_view", categorySlug, false);
};

const isDefaultView = (transition) => {
  return transition.to.name === "discovery.category";
};

export { displayConnector, boardDefaultView, isDefaultView, getCurrentCategoryFromUrl };

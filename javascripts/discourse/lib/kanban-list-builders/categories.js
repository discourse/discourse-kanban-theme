import Category from "discourse/models/category";
import Site from "discourse/models/site";

export default function buildCategoryLists({ kanbanManager, param }) {
  const lists = [];

  if (param) {
    let categories = param
      .split(",")
      .map((c) => Category.findBySlug(...c.split("/").reverse()));
    categories.filter((c) => c !== undefined);

    lists.push(
      ...categories.map((category) => {
        return {
          title: category.name,
          params: {
            category: category.id,
          },
        };
      })
    );
  } else if (kanbanManager.discoveryCategory) {
    lists.push({
      title: kanbanManager.discoveryCategory.name,
      params: {
        category: kanbanManager.discoveryCategory.id,
        no_subcategories: true,
      },
    });

    if (kanbanManager.discoveryCategory.subcategories) {
      lists.push(
        ...kanbanManager.discoveryCategory.subcategories.map((category) => {
          return {
            title: `${kanbanManager.discoveryCategory.name} / ${category.name}`,
            params: {
              category: category.id,
            },
          };
        })
      );
    }
  } else {
    const categories = Site.currentProp("categoriesList").filter(
      (c) => !c.parent_category_id
    );

    lists.push(
      ...categories.map((category) => {
        return {
          title: category.name,
          params: {
            category: category.id,
          },
        };
      })
    );
  }

  return { lists };
}

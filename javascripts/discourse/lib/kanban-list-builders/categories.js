import Category from "discourse/models/category";
import Site from "discourse/models/site";

export default function buildCategoryLists({ kanbanHelper, param }) {
  const lists = [];

  if (param) {
    let categories = param
      .split(",")
      .map((c) => Category.findBySlug(...c.split("/").reverse()));
    categories.filter((c) => c !== undefined);

    lists.push(
      ...categories.map((category) => {
        return {
          title: `${category.name}`,
          params: {
            category: category.id,
          },
        };
      })
    );
  } else if (kanbanHelper.discoveryCategory) {
    lists.push({
      title: `${kanbanHelper.discoveryCategory.name}`,
      params: {
        category: kanbanHelper.discoveryCategory.id,
        no_subcategories: true,
      },
    });

    if (kanbanHelper.discoveryCategory.subcategories) {
      lists.push(
        ...kanbanHelper.discoveryCategory.subcategories.map((category) => {
          return {
            title: `${kanbanHelper.discoveryCategory.name} / ${category.name}`,
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
          title: `${category.name}`,
          params: {
            category: category.id,
          },
        };
      })
    );
  }

  return { lists };
}

import { displayConnector, getCurrentCategoryUrl } from "../../lib/kanban-utilities";

export default {
  shouldRender(args, component) {
    const slug_fixed = component.get("category.slug") || getCurrentCategoryUrl();
    console.log(`${slug_fixed}`)
    return displayConnector(slug_fixed);
  },
};

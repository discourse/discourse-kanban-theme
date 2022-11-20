import { displayConnector, getCurrentCategoryFromUrl } from "../../lib/kanban-utilities";

export default {
  shouldRender(args, component) {
    const slug_fixed = (args.category && args.category.slug) || getCurrentCategoryFromUrl();
    return displayConnector(slug_fixed);
  },
};

import { displayConnector } from "../../lib/kanban-utilities";

export default {
  shouldRender(outletArgs) {
    return displayConnector(outletArgs.category?.slug);
  },
};

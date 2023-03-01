import { displayConnector } from "../../lib/kanban-utilities";

export default {
  shouldRender(args) {
    return displayConnector(args?.category?.slug || args?.category?.name);
  },
};

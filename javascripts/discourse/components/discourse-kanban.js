import Component from "@ember/component";
import { inject as service } from "@ember/service";
import discourseComputed from "discourse-common/utils/decorators";
import showModal from "discourse/lib/show-modal";

export default Component.extend({
  tagName: "div",
  classNames: "discourse-kanban",
  classNameBindings: "fullscreen",
  kanbanHelper: service(),

  @discourseComputed("kanbanHelper.active")
  shouldDisplay(active) {
    return active;
  },

  actions: {
    setDragData(data) {
      this.set("dragData", data);
    },

    toggleFullscreen() {
      this.toggleProperty("fullscreen");
      this.kanbanHelper.setFullscreen(this.fullscreen);
    },

    openSettings() {
      showModal("kanban-options");
    },
  },
});

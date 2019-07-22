import computed from "ember-addons/ember-computed-decorators";
import showModal from "discourse/lib/show-modal";

export default Ember.Component.extend({
    tagName: "div",
    classNames: "discourse-kanban",
    classNameBindings: "fullscreen",
    kanbanHelper: Ember.inject.service(),

    @computed("kanbanHelper.active")
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
      }
    }
  })
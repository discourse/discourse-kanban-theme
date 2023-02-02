import Component from "@ember/component";
import { inject as service } from "@ember/service";
import discourseComputed from "discourse-common/utils/decorators";
import showModal from "discourse/lib/show-modal";
import { action } from "@ember/object";

export default class Kanban extends Component {
  tagName = "div";
  classNames = ["discourse-kanban"];
  classNameBindings = ["fullscreen"];
  @service kanbanHelper;

  @discourseComputed("kanbanHelper.active")
  shouldDisplay(active) {
    return active;
  }

  @action
  setDragData(data) {
    this.set("dragData", data);
  }

  @action
  toggleFullscreen() {
    this.toggleProperty("fullscreen");
    this.kanbanHelper.setFullscreen(this.fullscreen);
  }

  @action
  openSettings() {
    showModal("kanban-options");
  }
}

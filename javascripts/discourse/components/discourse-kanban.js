import Component from "@ember/component";
import { inject as service } from "@ember/service";
import discourseComputed from "discourse-common/utils/decorators";
import { action } from "@ember/object";
import KanbanOptionsModal from "./modal/discourse-kanban-options";

export default class Kanban extends Component {
  @service kanbanHelper;
  @service modal;

  tagName = "div";
  classNames = ["discourse-kanban"];
  classNameBindings = ["fullscreen"];

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
    this.modal.show(KanbanOptionsModal);
  }
}

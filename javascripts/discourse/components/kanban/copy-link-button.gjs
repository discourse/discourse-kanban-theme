import Component from "@glimmer/component";
import DButton from "discourse/components/d-button";
import { action } from "@ember/object";
import discourseDebounce from "discourse-common/lib/debounce";
import { tracked } from "@glimmer/tracking";

export default class KanbanCopyLinkButton extends Component {
  <template>
    <DButton
      @icon={{if this.copyConfirm "check" "copy"}}
      class={{if this.copyConfirm "ok"}}
      @action={{this.copy}}
      title={{themePrefix "copy_link"}}
    />
  </template>

  @tracked copyConfirm = false;

  @action
  copy() {
    const text = document.location;
    navigator.clipboard.writeText(text);
    this.copyConfirm = true;
    discourseDebounce(this.resetCopyButton, 2000);
  }

  @action
  resetCopyButton() {
    this.copyConfirm = false;
  }
}

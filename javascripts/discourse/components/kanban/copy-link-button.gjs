import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import DButton from "discourse/components/d-button";
import concatClass from "discourse/helpers/concat-class";
import discourseDebounce from "discourse/lib/debounce";

export default class KanbanCopyLinkButton extends Component {
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

  <template>
    <DButton
      @icon={{if this.copyConfirm "check" "copy"}}
      class={{concatClass "btn-transparent"}}
      @action={{this.copy}}
      @label={{themePrefix "copy_link"}}
    />
  </template>
}

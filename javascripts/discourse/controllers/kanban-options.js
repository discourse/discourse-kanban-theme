import Controller from "@ember/controller";
import { inject as service } from "@ember/service";
import DiscourseURL from "discourse/lib/url";
import ModalFunctionality from "discourse/mixins/modal-functionality";
import { equal } from "@ember/object/computed";
import { action } from "@ember/object";

export default class KanbanOptionsController extends Controller.extend(
  ModalFunctionality
) {
  @service kanbanHelper;
  modes = [{ id: "tags" }, { id: "categories" }, { id: "assigned" }];
  tags = [];
  usernames = [];
  categories = [];
  mode = "tags";

  @equal("mode", "tags") isTags;
  @equal("mode", "categories") isCategories;
  @equal("mode", "assigned") isAssigned;

  @action
  apply() {
    let href = this.kanbanHelper.hrefForCategory(
      this.kanbanHelper.discoveryCategory
    );
    href += "?board=";
    if (this.isTags) {
      href += "tags";
      if (this.tags.length > 0) {
        href += `:${this.tags.join(",")}`;
      }
    } else if (this.isCategories) {
      href += "categories";
      if (this.categories.length > 0) {
        href += `:${this.categories.join(",")}`;
      }
    } else if (this.isAssigned) {
      href += "assigned";
      if (this.usernames.length > 0) {
        href += `:${this.usernames}`;
      }
    }

    this.send("closeModal");
    DiscourseURL.routeTo(href, { replaceURL: true });
  }
}

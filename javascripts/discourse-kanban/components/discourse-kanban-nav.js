import Component from "@ember/component";
import { inject as service } from "@ember/service";
import discourseComputed from "discourse-common/utils/decorators";
import DiscourseURL from "discourse/lib/url";
import { getCurrentCategoryUrl } from "../lib/kanban-utilities";

export default Component.extend({
  tagName: "a",
  attributeBindings: "href",
  classNameBindings: "active",
  kanbanHelper: service(),

  @discourseComputed("category")
  href(category) {
    return this.kanbanHelper.hrefForCategory(category);
  },

  @discourseComputed("filterMode", "kanbanHelper.active")
  active(filterMode, active) {
    return filterMode.split("/").pop() === "latest" && active;
  },

  click(event) {
    const get_mode = () => {
      const nowat = getCurrentCategoryUrl();
      const mode_set = settings["default_modes"].split("|")
      let returns = "default";
      for (const mode_to_apply of mode_set) {
        const sets_of_cate = mode_to_apply.split(":");
        if (nowat === sets_of_cate[0]) {
          returns = sets_of_cate[1];
          break;
        }
      }
      return returns;
    }
    
    event.preventDefault();
    DiscourseURL.routeTo(`${this.href}?board=${get_mode()}`);
  },
});

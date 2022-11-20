import Component from "@ember/component";
import { inject as service } from "@ember/service";
import discourseComputed from "discourse-common/utils/decorators";
import DiscourseURL from "discourse/lib/url";
import { getCurrentCategoryFromUrl } from "../lib/kanban-utilities";

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
    // Bypass wrong slug acquisition method
    const getDefaultMode = () => {
      const categorySlug = getCurrentCategoryFromUrl();
      const defaultModesSet = settings["default_modes"].split("|")
      let returns = "default";

      for (const defaultModeSettings of defaultModesSet) {
        const FIRST_COLON_INDEX = defaultModeSettings.indexOf(':');
        const defaultModeCategorySlug = defaultModeSettings.substring(0, FIRST_COLON_INDEX);
        if (categorySlug == defaultModeCategorySlug) {
          returns = defaultModeSettings.substring(FIRST_COLON_INDEX + 1);
        }
      }
      return returns;
    }
    
    event.preventDefault();
    DiscourseURL.routeTo(`${this.href}?board=${getDefaultMode()}`);
  },
});

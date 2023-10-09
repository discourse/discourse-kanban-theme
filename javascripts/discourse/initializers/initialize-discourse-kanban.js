import { inject as service } from "@ember/service";
import { withPluginApi } from "discourse/lib/plugin-api";
import discourseComputed from "discourse-common/utils/decorators";
import {
  boardDefaultView,
  displayConnector,
  isDefaultView,
} from "../lib/kanban-utilities";
import { next } from "@ember/runloop";
import DiscourseKanban from "../components/kanban/wrapper";
import DiscourseKanbanNav from "../components/kanban/nav";

const PLUGIN_ID = "kanban-board";

export default {
  name: "my-initializer",
  initialize() {
    withPluginApi("0.8.7", (api) => {
      api.renderInOutlet("discovery-list-container-top", DiscourseKanban);
      api.renderInOutlet("extra-nav-item", DiscourseKanbanNav);

      api.addDiscoveryQueryParam("board", {
        replace: true,
        refreshModel: true,
      });

      api.modifyClass("component:navigation-item", {
        pluginId: PLUGIN_ID,

        kanbanManager: service(),
        @discourseComputed(
          "content.filterMode",
          "filterMode",
          "kanbanManager.active"
        )
        active(contentFilterMode, filterMode, active) {
          if (active) {
            return false;
          }
          return this._super(contentFilterMode, filterMode);
        },
      });

      const routeToBoard = (transition, categorySlug) => {
        return (
          isDefaultView(transition) &&
          displayConnector(categorySlug) &&
          boardDefaultView(categorySlug)
        );
      };

      ["category", "categoryNone"].forEach(function (route) {
        api.modifyClass(`route:discovery.${route}`, {
          pluginId: PLUGIN_ID,

          redirect(model, transition) {
            if (routeToBoard(transition, model.category.slug)) {
              // This redirect breaks the `new-topic` system, so we have to re-implement here
              let newTopicParams;
              if (window.location.pathname.includes("/new-topic")) {
                const params = new URLSearchParams(window.location.search);
                newTopicParams = [
                  params.title,
                  params.body,
                  model.category.id,
                  params.tags,
                ];
              }
              return this.transitionTo(
                "discovery.latestCategory",
                model.category.id,
                { queryParams: { board: "default" } }
              ).finally(() => {
                if (newTopicParams) {
                  next(() =>
                    this.send("createNewTopicViaParams", ...newTopicParams)
                  );
                }
              });
            } else {
              return this._super(...arguments);
            }
          },
        });
      });
    });
  },
};

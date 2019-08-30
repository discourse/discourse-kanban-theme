import { withPluginApi } from "discourse/lib/plugin-api";
import {default as computed, on, observes} from "ember-addons/ember-computed-decorators";
import { displayConnector, boardDefaultView, isDefaultView } from '../lib/kanban-utilities'; 

export default {
  name: "my-initializer",
  initialize(){
    withPluginApi("0.8.7", api => {
        api.addDiscoveryQueryParam("board", { replace: true, refreshModel: true });
  
        api.modifyClass("controller:discovery/topics", {
            kanbanHelper: Ember.inject.service(),
        
            @on("init")
            @observes("model")
            modelChange() {
            this.kanbanHelper.updateCurrentDiscoveryModel(this.model);
            },
        
            @on("init")
            @observes("category")
            changeCategory() {
            this.kanbanHelper.updateCurrentCategory(this.category);
            }
        });
        
        api.modifyClass("component:navigation-item", {
            kanbanHelper: Ember.inject.service(),
            @computed("content.filterMode", "filterMode", "kanbanHelper.active")
            active(contentFilterMode, filterMode, active) {
            if (active) {
                return false;
            }
            return this._super(contentFilterMode, filterMode);
            }
        });
        
        const routeToBoard = (transition, categorySlug) => {
          return isDefaultView(transition) &&
            displayConnector(categorySlug) &&
            boardDefaultView(categorySlug);
        }

        [
         'category',
         'parentCategory',
         'categoryNone',
         'categoryWithID'
        ].forEach(function(route){
          api.modifyClass(`route:discovery.${route}`, {
            afterModel(model, transition) {
              if (routeToBoard(transition, model.category.slug)) {
                return this.replaceWith(`${model.category.get('url')}/l/latest?board=default`);
              } else {
                return this._super(...arguments);
              }
            }
          });
        });
    });
  }
}
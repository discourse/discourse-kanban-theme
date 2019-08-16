import {default as computed, observes} from "ember-addons/ember-computed-decorators";
import showModal from "discourse/lib/show-modal";

export default Ember.Component.extend({
    tagName: "div",
    classNames: "discourse-kanban",
    classNameBindings: "fullscreen",
    kanbanHelper: Ember.inject.service(),

    @computed("kanbanHelper.active")
    shouldDisplay(active) {
        if (active) this.refreshDefinitions()
        return active;
    },

    /**
     * Lifecycle hook required to build columns asynchronously in certain cases
     * 1) in tag discovery mode, displaying tag columns/lists:
     *    when user has not specified explicit columns to include, kabanHelper returns empty list..
     *    need to look up list of tags in the db,
     *    and filter out empty ones
     * 2) in tag discovery mode, displaying category columns/lists:
     *    default behaviour shows ALL categories, including empty ones
     *    need to be filtered out by looking up # of topics in the db
     */
    refreshDefinitions() {
        this._super(...arguments);

        const definitions = this.kanbanHelper.listDefinitions;
        const category = this.kanbanHelper.discoveryCategory ? this.kanbanHelper.discoveryCategory.slug : undefined;
        const tag = this.kanbanHelper.discoveryTag? this.kanbanHelper.discoveryTag.id : undefined;
        const board = this.kanbanHelper.discoveryParams.board;

        const setDefaults = settings.display_modes
            .split("|")
            .map(m => m.split(":"));
        const lookup = category || tag || "@";
        const defaultMode = setDefaults.find(m => m[0] === lookup);

        // triggered when in tag discovery mode, with tag columns/lists
        if (
            tag &&
            definitions === "async_lookup_tags"
        ) {
            const asyncDefinitions_unfiltered = [];
            this.store.findAll("tag").then(results => {

                results.content.forEach(t => {
                    asyncDefinitions_unfiltered.push({
                        title: `#${t.id}`,
                        params: {
                            tags: t.id
                        }
                    });
                });
                this.filterTagDefinitions(asyncDefinitions_unfiltered);
            });
        }

        // only trigger column filtering when there are no pre-defined columns to display (via settings) and when we are in tag discovery mode, displaying category columns
        else if (
            definitions &&
            tag && // user building a Kanban board in tag discovery mode
            ((definitions[0].params.category && // user building lists out of categories (i.e. category key exists)
            !defaultMode // user not set a default mode list of categories to display for this board
            ) || board === "categories") // OR user has changed settings modal to display categories, without specifying which ones
        ) {
            console.log('test')
            this.filterTagDefinitions(definitions);
        }

        // base case
        else {
            console.log('fail')
            this.set("definitions", definitions);
        }
    },

    /**
     * Helper function for tag discovery mode to query db for topics under each list
     * then removes empty lists from definitions array:
     *  1) category lists (d.params.category is truthy):
     *     queries topics under each category list for the current discovery tag
     *  2) tag lists (d.params.tags is truthy):
     *     queries topics under each tag list... then filters offline to only keep topics that include current
     *     discovery tag (unable to find method for querying topics filtered by more than 1 tag).
     */
    filterTagDefinitions(definitions_unfiltered) {
        const tag = this.kanbanHelper.discoveryTag;
        const promises = definitions_unfiltered.map(d => {

            const params = {};
            if (d.params.category) params.category = d.params.category;
            if (d.params.tags) params.tag = d.params.tags;
            
            const storeOptions = {};
            storeOptions.params = params;
            if (d.params.category) storeOptions.filter = `tags/${tag.id}`
            if (d.params.tags) storeOptions.filter = `tags/${d.params.tags}`

            return this.store.findFiltered("topicList", storeOptions);
        });
        // need to settle all promises before continuing, otherwise we get weird async behaviour
        Promise.all(promises).then(lists => {
            lists.forEach((list, index) => {
                    const topics = list.topics;

                    // not sure how to run findFiltered() against multiple tags
                    // (required for tag-based boards that are also showing tag-based columns)
                    // so doing an extra step here to filter out topics in a column that don't carry the discovery Tag
                    if (this.kanbanHelper.listDefinitions === "async_lookup_tags" && topics.length > 0) {
                        const topics_filtered = topics.filter(topic => topic.tags.includes(tag.id))
                        definitions_unfiltered[index].topics = topics_filtered;
                    } else {
                        definitions_unfiltered[index].topics = topics;
                    }
                });
            const definitions_filtered = definitions_unfiltered
                .filter(d => d.topics.length > 0)
                .filter(d => d.params.tags != tag.id); // exclude board parent tag from board columns
            console.log('definitions after promises', definitions_filtered);
            this.set("definitions", definitions_filtered);
        });
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
});
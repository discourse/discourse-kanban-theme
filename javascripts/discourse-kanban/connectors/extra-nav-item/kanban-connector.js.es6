export default {
    shouldRender(args, component) {
        if (settings.display_categories === "") return true;
    
        const displayCategories = settings.display_categories.split("|");
        const lookup = component.get("category.slug") || "@";
        console.log(lookup, displayCategories);
        return displayCategories.includes(lookup);
    }
}
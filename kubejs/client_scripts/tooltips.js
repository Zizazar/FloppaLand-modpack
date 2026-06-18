ItemEvents.tooltip(event => {
    event.addAdvanced("computercraft:disk", (item, advanced, text) => {
        text.add(1, Text.of('Floppa disk').yellow());
        text.add(2, Text.of('5 МБ').green());

    })
})
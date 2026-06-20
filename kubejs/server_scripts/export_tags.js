ServerEvents.commandRegistry(event => {
    const { commands: Commands } = event;

    event.register(
        // Регистрируем команду /export_tags
        Commands.literal('export_tags')
            .requires(src => src.hasPermission(2)) // Доступно только операторам (OP) или в консоли
            .executes(ctx => {
                let tagsData = {};
                let allItemIds = Ingredient.all.itemIds;

                // Перебираем все предметы и их теги
                allItemIds.forEach(id => {
                    let itemId = id.toString();
                    let itemStack = Item.of(itemId);

                    itemStack.tags.forEach(tag => {
                        let tagId = tag.toString();

                        if (!tagsData[tagId]) {
                            tagsData[tagId] = [];
                        }

                        if (!tagsData[tagId].includes(itemId)) {
                            tagsData[tagId].push(itemId);
                        }
                    });
                });

                // Экспортируем данные
                JsonIO.write('kubejs/exported_item_tags.json', tagsData);

                // Отправляем уведомление об успехе
                if (ctx.source.player) {
                    ctx.source.player.tell(Text.green('Экспорт тегов завершен! Файл: kubejs/exported_item_tags.json'));
                } else {
                    console.info('Экспорт тегов завершен! Файл: kubejs/exported_item_tags.json');
                }

                return 1; // Возвращаем 1 для индикации успешного выполнения
            })
    );
});
StartupEvents.registry('item', event => {
  event.create('alloy_reinforced_base')
  event.create('glowstone_mix')
  event.create('alloy_atomic_base')

  event.create('ethene_bottle')
    .use((level, player, hand) => true)
    .useAnimation("drink")
    .useDuration((itemstack) => 32)
    .finishUsing((itemstack, level, entity) => {
        if (entity.player) {
            let item = entity.getHeldItem('main_hand');
            if (item.id == 'kubejs:ethene_bottle') {
                item.count--
                level.server.runCommandSilent(`kick ${entity.player.username} Вы были крашнуты при попытке употребления этилена внутрь`)
            }
        }
        return itemstack;
    })
})
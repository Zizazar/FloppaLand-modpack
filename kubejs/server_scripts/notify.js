const StringArgumentType = Java.loadClass('com.mojang.brigadier.arguments.StringArgumentType');

ServerEvents.commandRegistry(event => {
  const { commands: Commands } = event;

  const sendNotification = (server, msg, sound) => {
    server.players.forEach(player => {

      if (player.persistentData.getBoolean('disable_notify')) return;

      player.tell(Component.white("[").append(Text.gold("Floppa")).append(Text.darkAqua("Land")).append(Text.white("] ")).append(msg))
      
      if (sound) {
        player.playSound(sound, 1.5, 0.5)
      } else {
        player.playSound("minecraft:entity.experience_orb.pickup", 1.5, 0.5)
      }

    });
  };

  event.register(
    Commands.literal('notify')
    
      // =========================================================
      // All players
      // =========================================================
      .then(Commands.literal('disable')
        .executes(ctx => {
          let player = ctx.source.player;
          if (!player) return 0;
          
          player.persistentData.putBoolean('disable_notify', true);
          player.tell(Text.red('Вы отключили получение серверных уведомлений'));
          return 1;
        })
      )
      .then(Commands.literal('enable')
        .executes(ctx => {
          let player = ctx.source.player;
          if (!player) return 0;
          
          player.persistentData.putBoolean('disable_notify', false);
          player.tell(Text.green('Вы снова будете получать серверные уведомления'));
          return 1;
        })
      )

      // =========================================================
      // Admin only
      // =========================================================
      
      // BACKUP
      .then(Commands.literal('backup')
        .requires(src => src.hasPermission(2))
        .then(Commands.literal('start')
          .executes(ctx => {
            sendNotification(
              ctx.source.server, 
              'Выполняется резервное копирование сервера'
            );
            return 1;
          })
        )
        .then(Commands.literal('end')
          .executes(ctx => {
            sendNotification(
              ctx.source.server, 
              Text.green('Резервное копирование завершено!')
            );
            return 1;
          })
        )
        .then(Commands.literal('error')
          .executes(ctx => {
            sendNotification(
              ctx.source.server,
              Text.red("Ошибка резервного копирования")
            )
            return 1;
          })
      ))

      // RESTART
      .then(Commands.literal('restart')
        .requires(src => src.hasPermission(2))

        .then(Commands.argument('time', StringArgumentType.greedyString())
          .executes(ctx => {
            let timeStr = StringArgumentType.getString(ctx, 'time');
            sendNotification(
              ctx.source.server, 
              `Рестарт сервера через ${timeStr}`
            );
            return 1;
          })
        )
      )

      .then(Commands.literal('custom')
        .requires(src => src.hasPermission(2))
        .then(Commands.argument('message', StringArgumentType.greedyString())
          .executes(ctx => {
            let msg = StringArgumentType.getString(ctx, 'message');
            sendNotification(
              ctx.source.server, 
              msg
            );
            return 1;
          })
        )
      )
  );
});
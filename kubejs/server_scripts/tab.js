const $SparkProvider = Java.loadClass("me.lucko.spark.api.SparkProvider");
const $TicksPerSecond = Java.loadClass("me.lucko.spark.api.statistic.StatisticWindow$TicksPerSecond");

const $ClientboundTabListPacket = Java.loadClass('net.minecraft.network.protocol.game.ClientboundTabListPacket');
const $StatType = Java.loadClass('net.minecraft.stats.Stats');

const logMethods = (obj) => console.log(
  Object.keys(obj).filter(key => typeof obj[key] === 'function')
);

ServerEvents.tick(event => {

    let /**@type {Internal.Server} */ server = event.server; 

    if (server.tickCount % 20 !== 0) return;

    let spark = $SparkProvider.get()

    let stats = spark.tps()
    let tpsText = Text.darkRed("Error")
    if (stats) {
        let tps = stats.poll($TicksPerSecond.SECONDS_10)
        let tpsString = Number(tps).toFixed(1);

        if (tps >= 18.0) {
            tpsText = Text.green(tpsString);
        } else if (tps >= 15.0) {
            tpsText = Text.yellow(tpsString);
        } else {
            tpsText = Text.red(tpsString);
        }
    }
    
    function formatTime(tick) {
        let seconds = Math.floor(tick / 20);
        let minutes = Math.floor(seconds / 60);
        let hours = Math.floor(minutes / 60);
        // eg 12 h 30 m 45 s
        
        return `${hours}h ${minutes % 60}m ${seconds % 60}s`;
    }

    event.server.players.forEach(player => {
        let playTime = player.server.getPlayerList().getPlayerStats(player).getValue($StatType.PLAY_TIME);
        let deaths = player.server.getPlayerList().getPlayerStats(player).getValue($StatType.DEATHS);

        let pos = player.blockPosition()


        let header = Text.of("§6§lFloppa Land 4\n");
        
        let footer = Text.of("\n")
            .append(Text.gray("TPS: ").append(tpsText))
            .append(Text.of("\n"))
            .append(Text.gray("☠ ").append(Text.of(deaths)))
            .append(Text.of("\n"))
            .append(Text.darkAqua("⌚ " + formatTime(playTime)));

        try {
            let packet = new $ClientboundTabListPacket(header, footer);
            player.connection.send(packet);
        } catch (e) {
        }
    });
});
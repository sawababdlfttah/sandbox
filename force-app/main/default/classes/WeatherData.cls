public class WeatherData {
    @AuraEnabled public Decimal temperature { get; set; }
    @AuraEnabled public Decimal windSpeed { get; set; }
    @AuraEnabled public Decimal humidity { get; set; }
    @AuraEnabled public String clouds { get; set; }
}
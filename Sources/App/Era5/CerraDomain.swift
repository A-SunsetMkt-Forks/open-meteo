import Foundation
import Vapor
@preconcurrency import SwiftEccodes
import OmFileFormat

typealias CerraHourlyVariable = VariableOrDerived<CerraVariable, CerraVariableDerived>

enum CerraVariableDerived: String, RawRepresentableString, GenericVariableMixable {
    case apparent_temperature
    case dewpoint_2m
    case dew_point_2m
    case vapor_pressure_deficit
    case vapour_pressure_deficit
    case diffuse_radiation
    case surface_pressure
    case snowfall
    case rain
    case et0_fao_evapotranspiration
    case cloudcover
    case cloud_cover
    case direct_normal_irradiance
    case weathercode
    case weather_code
    case is_day
    case terrestrial_radiation
    case terrestrial_radiation_instant
    case shortwave_radiation_instant
    case diffuse_radiation_instant
    case direct_radiation_instant
    case direct_normal_irradiance_instant
    case global_tilted_irradiance
    case global_tilted_irradiance_instant
    case wet_bulb_temperature_2m
    case windspeed_10m
    case winddirection_10m
    case windspeed_100m
    case winddirection_100m
    case wind_gusts_10m
    case relative_humidity_2m
    case cloud_cover_low
    case cloud_cover_mid
    case cloud_cover_high
    case sunshine_duration

    var requiresOffsetCorrectionForMixing: Bool {
        return false
    }
}

struct CerraReader: GenericReaderDerivedSimple, GenericReaderProtocol {
    let reader: GenericReaderCached<CdsDomain, CerraVariable>

    let options: GenericReaderOptions

    typealias Domain = CdsDomain

    typealias Variable = CerraVariable

    typealias Derived = CerraVariableDerived

    public init?(domain: Domain, lat: Float, lon: Float, elevation: Float, mode: GridSelectionMode, options: GenericReaderOptions) async throws {
        guard let reader = try await GenericReader<Domain, Variable>(domain: domain, lat: lat, lon: lon, elevation: elevation, mode: mode, options: options) else {
            return nil
        }
        self.reader = GenericReaderCached(reader: reader)
        self.options = options
    }

    public init(domain: Domain, gridpoint: Int, options: GenericReaderOptions) async throws {
        let reader = try await GenericReader<Domain, Variable>(domain: domain, position: gridpoint, options: options)
        self.reader = GenericReaderCached(reader: reader)
        self.options = options
    }

    func prefetchData(variables: [CerraHourlyVariable], time: TimerangeDtAndSettings) async throws {
        for variable in variables {
            switch variable {
            case .raw(let v):
                try await prefetchData(raw: v, time: time)
            case .derived(let v):
                try await prefetchData(derived: v, time: time)
            }
        }
    }

    func prefetchData(derived: CerraVariableDerived, time: TimerangeDtAndSettings) async throws {
        switch derived {
        case .apparent_temperature:
            try await prefetchData(raw: .temperature_2m, time: time)
            try await prefetchData(raw: .wind_speed_10m, time: time)
            try await prefetchData(raw: .relative_humidity_2m, time: time)
            try await prefetchData(raw: .direct_radiation, time: time)
            try await prefetchData(raw: .shortwave_radiation, time: time)
        case .dew_point_2m, .dewpoint_2m:
            try await prefetchData(raw: .temperature_2m, time: time)
            try await prefetchData(raw: .relative_humidity_2m, time: time)
        case .vapour_pressure_deficit, .vapor_pressure_deficit:
            try await prefetchData(raw: .temperature_2m, time: time)
            try await prefetchData(raw: .relative_humidity_2m, time: time)
        case .global_tilted_irradiance, .global_tilted_irradiance_instant, .diffuse_radiation:
            try await prefetchData(raw: .shortwave_radiation, time: time)
            try await prefetchData(raw: .direct_radiation, time: time)
        case .et0_fao_evapotranspiration:
            try await prefetchData(raw: .direct_radiation, time: time)
            try await prefetchData(derived: .diffuse_radiation, time: time)
            try await prefetchData(raw: .temperature_2m, time: time)
            try await prefetchData(raw: .relative_humidity_2m, time: time)
            try await prefetchData(raw: .wind_speed_10m, time: time)
        case .surface_pressure:
            try await prefetchData(raw: .pressure_msl, time: time)
        case .snowfall:
            try await prefetchData(raw: .snowfall_water_equivalent, time: time)
        case .cloud_cover, .cloudcover:
            try await prefetchData(raw: .cloud_cover_low, time: time)
            try await prefetchData(raw: .cloud_cover_mid, time: time)
            try await prefetchData(raw: .cloud_cover_high, time: time)
        case .direct_normal_irradiance:
            try await prefetchData(raw: .direct_radiation, time: time)
        case .rain:
            try await prefetchData(raw: .precipitation, time: time)
            try await prefetchData(raw: .snowfall_water_equivalent, time: time)
        case .weather_code, .weathercode:
            try await prefetchData(derived: .cloudcover, time: time)
            try await prefetchData(raw: .precipitation, time: time)
            try await prefetchData(derived: .snowfall, time: time)
        case .is_day:
            break
        case .terrestrial_radiation:
            break
        case .terrestrial_radiation_instant:
            break
        case .shortwave_radiation_instant:
            try await prefetchData(raw: .shortwave_radiation, time: time)
        case .diffuse_radiation_instant:
            try await prefetchData(derived: .diffuse_radiation, time: time)
        case .direct_radiation_instant:
            try await prefetchData(raw: .direct_radiation, time: time)
        case .direct_normal_irradiance_instant:
            try await prefetchData(raw: .direct_radiation, time: time)
        case .wet_bulb_temperature_2m:
            try await prefetchData(raw: .temperature_2m, time: time)
            try await prefetchData(raw: .relative_humidity_2m, time: time)
        case .windspeed_10m:
            try await prefetchData(raw: .wind_speed_10m, time: time)
        case .winddirection_10m:
            try await prefetchData(raw: .wind_direction_10m, time: time)
        case .wind_gusts_10m:
            try await prefetchData(raw: .wind_gusts_10m, time: time)
        case .relative_humidity_2m:
            try await prefetchData(raw: .relative_humidity_2m, time: time)
        case .cloud_cover_low:
            try await prefetchData(raw: .cloud_cover_low, time: time)
        case .cloud_cover_mid:
            try await prefetchData(raw: .cloud_cover_mid, time: time)
        case .cloud_cover_high:
            try await prefetchData(raw: .cloud_cover_high, time: time)
        case .windspeed_100m:
            try await prefetchData(raw: .wind_speed_100m, time: time)
        case .winddirection_100m:
            try await prefetchData(raw: .wind_speed_100m, time: time)
        case .sunshine_duration:
            try await prefetchData(raw: .direct_radiation, time: time)
        }
    }

    func get(variable: CerraHourlyVariable, time: TimerangeDtAndSettings) async throws -> DataAndUnit {
        switch variable {
        case .raw(let variable):
            return try await get(raw: variable, time: time)
        case .derived(let variable):
            return try await get(derived: variable, time: time)
        }
    }

    func get(derived: CerraVariableDerived, time: TimerangeDtAndSettings) async throws -> DataAndUnit {
        switch derived {
        case .dew_point_2m, .dewpoint_2m:
            let relhum = try await get(raw: .relative_humidity_2m, time: time)
            let temperature = try await get(raw: .temperature_2m, time: time)
            return DataAndUnit(zip(temperature.data, relhum.data).map(Meteorology.dewpoint), temperature.unit)
        case .apparent_temperature:
            let windspeed = try await get(raw: .wind_speed_10m, time: time).data
            let temperature = try await get(raw: .temperature_2m, time: time).data
            let relhum = try await get(raw: .relative_humidity_2m, time: time).data
            let radiation = try await get(raw: .shortwave_radiation, time: time).data
            return DataAndUnit(Meteorology.apparentTemperature(temperature_2m: temperature, relativehumidity_2m: relhum, windspeed_10m: windspeed, shortwave_radiation: radiation), .celsius)
        case .vapour_pressure_deficit, .vapor_pressure_deficit:
            let temperature = try await get(raw: .temperature_2m, time: time).data
            let dewpoint = try await get(derived: .dewpoint_2m, time: time).data
            return DataAndUnit(zip(temperature, dewpoint).map(Meteorology.vaporPressureDeficit), .kilopascal)
        case .et0_fao_evapotranspiration:
            let exrad = Zensun.extraTerrestrialRadiationBackwards(latitude: modelLat, longitude: modelLon, timerange: time.time)
            let swrad = try await get(raw: .shortwave_radiation, time: time).data
            let temperature = try await get(raw: .temperature_2m, time: time).data
            let windspeed = try await get(raw: .wind_speed_10m, time: time).data
            let dewpoint = try await get(derived: .dewpoint_2m, time: time).data

            let et0 = swrad.indices.map { i in
                return Meteorology.et0Evapotranspiration(temperature2mCelsius: temperature[i], windspeed10mMeterPerSecond: windspeed[i], dewpointCelsius: dewpoint[i], shortwaveRadiationWatts: swrad[i], elevation: self.modelElevation.numeric, extraTerrestrialRadiation: exrad[i], dtSeconds: time.dtSeconds)
            }
            return DataAndUnit(et0, .millimetre)
        case .diffuse_radiation:
            let swrad = try await get(raw: .shortwave_radiation, time: time).data
            let direct = try await get(raw: .direct_radiation, time: time).data
            let diff = zip(swrad, direct).map(-)
            return DataAndUnit(diff, .wattPerSquareMetre)
        case .surface_pressure:
            let temperature = try await get(raw: .temperature_2m, time: time).data
            let pressure = try await get(raw: .pressure_msl, time: time)
            return DataAndUnit(Meteorology.surfacePressure(temperature: temperature, pressure: pressure.data, elevation: targetElevation), pressure.unit)
        case .cloud_cover, .cloudcover:
            let low = try await get(raw: .cloud_cover_low, time: time).data
            let mid = try await get(raw: .cloud_cover_mid, time: time).data
            let high = try await get(raw: .cloud_cover_high, time: time).data
            return DataAndUnit(Meteorology.cloudCoverTotal(low: low, mid: mid, high: high), .percentage)
        case .snowfall:
            let snowwater = try await get(raw: .snowfall_water_equivalent, time: time).data
            let snowfall = snowwater.map { $0 * 0.7 }
            return DataAndUnit(snowfall, .centimetre)
        case .direct_normal_irradiance:
            let dhi = try await get(raw: .direct_radiation, time: time).data
            let dni = Zensun.calculateBackwardsDNI(directRadiation: dhi, latitude: modelLat, longitude: modelLon, timerange: time.time)
            return DataAndUnit(dni, .wattPerSquareMetre)
        case .rain:
            let snowwater = try await get(raw: .snowfall_water_equivalent, time: time)
            let precip = try await get(raw: .precipitation, time: time)
            let rain = zip(precip.data, snowwater.data).map({
                return max($0.0 - $0.1, 0)
            })
            return DataAndUnit(rain, precip.unit)
        case .weather_code, .weathercode:
            let cloudcover = try await get(derived: .cloudcover, time: time).data
            let precipitation = try await get(raw: .precipitation, time: time).data
            let snowfall = try await get(derived: .snowfall, time: time).data
            return DataAndUnit(WeatherCode.calculate(
                cloudcover: cloudcover,
                precipitation: precipitation,
                convectivePrecipitation: nil,
                snowfallCentimeters: snowfall,
                gusts: nil,
                cape: nil,
                liftedIndex: nil,
                visibilityMeters: nil,
                categoricalFreezingRain: nil,
                modelDtSeconds: time.dtSeconds), .wmoCode
           )
        case .is_day:
            return DataAndUnit(Zensun.calculateIsDay(timeRange: time.time, lat: reader.modelLat, lon: reader.modelLon), .dimensionlessInteger)
        case .terrestrial_radiation:
            let solar = Zensun.extraTerrestrialRadiationBackwards(latitude: reader.modelLat, longitude: reader.modelLon, timerange: time.time)
            return DataAndUnit(solar, .wattPerSquareMetre)
        case .terrestrial_radiation_instant:
            let solar = Zensun.extraTerrestrialRadiationInstant(latitude: reader.modelLat, longitude: reader.modelLon, timerange: time.time)
            return DataAndUnit(solar, .wattPerSquareMetre)
        case .shortwave_radiation_instant:
            let sw = try await get(raw: .shortwave_radiation, time: time)
            let factor = Zensun.backwardsAveragedToInstantFactor(time: time.time, latitude: reader.modelLat, longitude: reader.modelLon)
            return DataAndUnit(zip(sw.data, factor).map(*), sw.unit)
        case .direct_normal_irradiance_instant:
            let direct = try await get(raw: .direct_radiation, time: time)
            let dni = Zensun.calculateBackwardsDNI(directRadiation: direct.data, latitude: reader.modelLat, longitude: reader.modelLon, timerange: time.time, convertToInstant: true)
            return DataAndUnit(dni, direct.unit)
        case .direct_radiation_instant:
            let direct = try await get(raw: .direct_radiation, time: time)
            let factor = Zensun.backwardsAveragedToInstantFactor(time: time.time, latitude: reader.modelLat, longitude: reader.modelLon)
            return DataAndUnit(zip(direct.data, factor).map(*), direct.unit)
        case .diffuse_radiation_instant:
            let diff = try await get(derived: .diffuse_radiation, time: time)
            let factor = Zensun.backwardsAveragedToInstantFactor(time: time.time, latitude: reader.modelLat, longitude: reader.modelLon)
            return DataAndUnit(zip(diff.data, factor).map(*), diff.unit)
        case .wet_bulb_temperature_2m:
            let relhum = try await get(raw: .relative_humidity_2m, time: time)
            let temperature = try await get(raw: .temperature_2m, time: time)
            return DataAndUnit(zip(temperature.data, relhum.data).map(Meteorology.wetBulbTemperature), temperature.unit)
        case .windspeed_10m:
            return try await get(raw: .wind_speed_10m, time: time)
        case .winddirection_10m:
            return try await get(raw: .wind_direction_10m, time: time)
        case .windspeed_100m:
            return try await get(raw: .wind_speed_100m, time: time)
        case .winddirection_100m:
            return try await get(raw: .wind_direction_100m, time: time)
        case .wind_gusts_10m:
            return try await get(raw: .wind_gusts_10m, time: time)
        case .relative_humidity_2m:
            return try await get(raw: .relative_humidity_2m, time: time)
        case .cloud_cover_low:
            return try await get(raw: .cloud_cover_low, time: time)
        case .cloud_cover_mid:
            return try await get(raw: .cloud_cover_mid, time: time)
        case .cloud_cover_high:
            return try await get(raw: .cloud_cover_high, time: time)
        case .sunshine_duration:
            let directRadiation = try await get(raw: .direct_radiation, time: time)
            let duration = Zensun.calculateBackwardsSunshineDuration(directRadiation: directRadiation.data, latitude: reader.modelLat, longitude: reader.modelLon, timerange: time.time)
            return DataAndUnit(duration, .seconds)
        case .global_tilted_irradiance:
            let directRadiation = try await get(raw: .direct_radiation, time: time).data
            let ghi = try await get(raw: .shortwave_radiation, time: time).data
            let diffuseRadiation = zip(ghi, directRadiation).map(-)
            let gti = Zensun.calculateTiltedIrradiance(directRadiation: directRadiation, diffuseRadiation: diffuseRadiation, tilt: options.tilt, azimuth: options.azimuth, latitude: reader.modelLat, longitude: reader.modelLon, timerange: time.time, convertBackwardsToInstant: false)
            return DataAndUnit(gti, .wattPerSquareMetre)
        case .global_tilted_irradiance_instant:
            let directRadiation = try await get(raw: .direct_radiation, time: time).data
            let ghi = try await get(raw: .shortwave_radiation, time: time).data
            let diffuseRadiation = zip(ghi, directRadiation).map(-)
            let gti = Zensun.calculateTiltedIrradiance(directRadiation: directRadiation, diffuseRadiation: diffuseRadiation, tilt: options.tilt, azimuth: options.azimuth, latitude: reader.modelLat, longitude: reader.modelLon, timerange: time.time, convertBackwardsToInstant: true)
            return DataAndUnit(gti, .wattPerSquareMetre)
        }
    }
}

/**
Sources:
 - https://cds.climate.copernicus.eu/cdsapp#!/dataset/reanalysis-cerra-land?tab=form
 - https://cds.climate.copernicus.eu/cdsapp#!/dataset/reanalysis-cerra-single-levels?tab=form
 - https://cds.climate.copernicus.eu/cdsapp#!/dataset/reanalysis-cerra-height-levels?tab=overview
 */
enum CerraVariable: String, CaseIterable, GenericVariable {
    case temperature_2m
    case wind_speed_10m
    case wind_direction_10m
    case wind_speed_100m
    case wind_direction_100m
    case wind_gusts_10m
    case relative_humidity_2m
    case cloud_cover_low
    case cloud_cover_mid
    case cloud_cover_high
    case pressure_msl
    case snowfall_water_equivalent
    /*case soil_temperature_0_to_7cm  // special dataset now, with very fine grained spacing ~1-4cm
    case soil_temperature_7_to_28cm
    case soil_temperature_28_to_100cm
    case soil_temperature_100_to_255cm
    case soil_moisture_0_to_7cm
    case soil_moisture_7_to_28cm
    case soil_moisture_28_to_100cm
    case soil_moisture_100_to_255cm*/
    case shortwave_radiation
    case precipitation
    case direct_radiation
    case albedo
    case snow_depth
    case snow_depth_water_equivalent

    var storePreviousForecast: Bool {
        return false
    }

    var isElevationCorrectable: Bool {
        return self == .temperature_2m
    }

    var omFileName: (file: String, level: Int) {
        return (rawValue, 0)
    }

    var interpolation: ReaderInterpolation {
        switch self {
        case .temperature_2m:
            return .hermite(bounds: nil)
        case .wind_speed_10m:
            return .hermite(bounds: nil)
        case .wind_direction_10m:
            return .linearDegrees
        case .wind_speed_100m:
            return .hermite(bounds: nil)
        case .wind_direction_100m:
            return .linearDegrees
        case .wind_gusts_10m:
            return .hermite(bounds: nil)
        case .relative_humidity_2m:
            return .hermite(bounds: 0...100)
        case .cloud_cover_low:
            return .hermite(bounds: 0...100)
        case .cloud_cover_mid:
            return .hermite(bounds: 0...100)
        case .cloud_cover_high:
            return .hermite(bounds: 0...100)
        case .pressure_msl:
            return .hermite(bounds: nil)
        case .snowfall_water_equivalent:
            return .backwards_sum
        case .shortwave_radiation:
            return .solar_backwards_averaged
        case .precipitation:
            return .backwards_sum
        case .direct_radiation:
            return .solar_backwards_averaged
        case .albedo:
            return .linear
        case .snow_depth, .snow_depth_water_equivalent:
            return .linear
        }
    }

    var requiresOffsetCorrectionForMixing: Bool {
         return false
    }

    /// Name used to query the ECMWF CDS API via python
    var cdsApiName: String {
        switch self {
        case .wind_gusts_10m: return "10m_wind_gust_since_previous_post_processing"
        case .relative_humidity_2m: return "2m_relative_humidity"
        case .temperature_2m: return "2m_temperature"
        case .cloud_cover_low: return "low_cloud_cover"
        case .cloud_cover_mid: return "medium_cloud_cover"
        case .cloud_cover_high: return "high_cloud_cover"
        case .pressure_msl: return "mean_sea_level_pressure"
        case .snowfall_water_equivalent: return "snow_fall_water_equivalent"
        case .shortwave_radiation: return "surface_solar_radiation_downwards"
        case .precipitation: return "total_precipitation"
        case .direct_radiation: return "time_integrated_surface_direct_short_wave_radiation_flux"
        case .wind_speed_10m: return "10m_wind_speed"
        case .wind_direction_10m: return "10m_wind_direction"
        case .wind_speed_100m: return "wind_speed"
        case .wind_direction_100m: return "wind_direction"
        case .albedo: return "albedo"
        case .snow_depth: return "snow_depth"
        case .snow_depth_water_equivalent: return "snow_depth_water_equivalent"
        }
    }

    var isAccumulatedSinceModelStart: Bool {
        switch self {
        case .shortwave_radiation, .direct_radiation, .precipitation, .snowfall_water_equivalent:
            return true
        default:
            return false
        }
    }

    var isHeightLevel: Bool {
        switch self {
        case .wind_speed_100m, .wind_direction_100m: return true
        default: return false
        }
    }

    /// Applied to the netcdf file after reading
    var netCdfScaling: (offest: Double, scalefactor: Double)? {
        switch self {
        case .temperature_2m: return (-273.15, 1) // kelvin to celsius
        case .shortwave_radiation, .direct_radiation: return (0, 1 / 3600) // joules to watt
        case .albedo: return (0, 100)
        case .snow_depth: return (0, 1 / 100) // cm to metre. GRIB files show metre, but it is cm
        default: return nil
        }
    }

    /// shortName attribute in GRIB
    var gribShortName: [String] {
        switch self {
        case .wind_speed_10m: return ["10si"]
        case .wind_direction_10m: return ["10wdir"]
        case .wind_speed_100m: return ["ws"]
        case .wind_direction_100m: return ["wdir"]
        case .wind_gusts_10m: return ["10fg", "gust"] // or "gust" on ubuntu 22.04
        case .relative_humidity_2m: return ["2r"]
        case .temperature_2m: return ["2t"]
        case .cloud_cover_low: return ["lcc"]
        case .cloud_cover_mid: return ["mcc"]
        case .cloud_cover_high: return ["hcc"]
        case .pressure_msl: return ["msl"]
        case .snowfall_water_equivalent: return ["sf"]
        case .shortwave_radiation: return ["ssrd"]
        case .precipitation: return ["tp"]
        case .direct_radiation: return ["tidirswrf"]
        case .albedo: return ["al"]
        case .snow_depth: return ["sd"]
        case .snow_depth_water_equivalent: return ["sde"]
        }
    }

    /// Scalefactor to compress data
    var scalefactor: Float {
        switch self {
        case .cloud_cover_low: return 1
        case .cloud_cover_mid: return 1
        case .cloud_cover_high: return 1
        case .wind_gusts_10m: return 10
        case .relative_humidity_2m: return 1
        case .temperature_2m: return 20
        case .pressure_msl: return 0.1
        case .snowfall_water_equivalent: return 10
        case .shortwave_radiation: return 1
        case .precipitation: return 10
        case .direct_radiation: return 1
        case .wind_speed_10m: return 10
        case .wind_direction_10m: return 0.5
        case .wind_speed_100m: return 10
        case .wind_direction_100m: return 0.5
        case .albedo: return 1
        case .snow_depth: return 100 // 1cm res
        case .snow_depth_water_equivalent: return 10 // 0.1mm res
        }
    }

    var unit: SiUnit {
        switch self {
        case .wind_speed_10m, .wind_speed_100m, .wind_gusts_10m: return .metrePerSecond
        case .wind_direction_10m: return .degreeDirection
        case .wind_direction_100m: return .degreeDirection
        case .relative_humidity_2m: return .percentage
        case .temperature_2m: return .celsius
        case .cloud_cover_low: return .percentage
        case .cloud_cover_mid: return .percentage
        case .cloud_cover_high: return .percentage
        case .pressure_msl: return .pascal
        case .snowfall_water_equivalent: return .millimetre
        case .shortwave_radiation: return .wattPerSquareMetre
        case .precipitation: return .millimetre
        case .direct_radiation: return .wattPerSquareMetre
        case .albedo: return .percentage
        case .snow_depth: return .metre
        case .snow_depth_water_equivalent: return .millimetre
        }
    }
}

/// On demand calculated variables
enum BomVariableDerived: String, CaseIterable, GenericVariableMixable {
    case apparent_temperature
    case relativehumidity_2m
    case dewpoint_2m
    case dew_point_2m
    case windspeed_10m
    case windspeed_40m
    case windspeed_80m
    case windspeed_120m
    case winddirection_10m
    case winddirection_40m
    case winddirection_80m
    case winddirection_120m

    case direct_normal_irradiance
    case direct_normal_irradiance_instant
    case direct_radiation_instant
    case diffuse_radiation_instant
    case diffuse_radiation
    case shortwave_radiation_instant
    case global_tilted_irradiance
    case global_tilted_irradiance_instant

    case et0_fao_evapotranspiration
    case vapour_pressure_deficit
    case vapor_pressure_deficit
    case surface_pressure
    case terrestrial_radiation
    case terrestrial_radiation_instant
    case weathercode
    case is_day
    case rain
    case snowfall
    case wet_bulb_temperature_2m
    case cloudcover
    case cloudcover_low
    case cloudcover_mid
    case cloudcover_high
    case windgusts_10m
    case sunshine_duration

    case soil_temperature_10_to_45cm
    case soil_temperature_40_to_100cm
    case soil_temperature_100_to_200cm

    case soil_moisture_10_to_40cm
    case soil_moisture_40_to_100cm
    case soil_moisture_100_to_200cm

    var requiresOffsetCorrectionForMixing: Bool {
        return false
    }
}

typealias BomVariableCombined = VariableOrDerived<BomVariable, BomVariableDerived>

struct BomReader: GenericReaderDerived, GenericReaderProtocol {
    typealias Domain = BomDomain

    typealias Variable = BomVariable

    typealias Derived = BomVariableDerived

    typealias MixingVar = BomVariableCombined

    let reader: GenericReaderCached<BomDomain, BomVariable>

    let options: GenericReaderOptions

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

    func get(raw: BomVariable, time: TimerangeDtAndSettings) async throws -> DataAndUnit {
        return try await reader.get(variable: raw, time: time)
    }

    func prefetchData(raw: BomVariable, time: TimerangeDtAndSettings) async throws {
        try await reader.prefetchData(variable: raw, time: time)
    }

    func prefetchData(derived: BomVariableDerived, time: TimerangeDtAndSettings) async throws {
        switch derived {
        case .apparent_temperature:
            try await prefetchData(raw: .temperature_2m, time: time)
            try await prefetchData(raw: .wind_speed_10m, time: time)
            try await prefetchData(raw: .relative_humidity_2m, time: time)
            try await prefetchData(raw: .shortwave_radiation, time: time)
        case .relativehumidity_2m:
            try await prefetchData(raw: .relative_humidity_2m, time: time)
        case .windspeed_10m:
            try await prefetchData(raw: .wind_speed_10m, time: time)
        case  .windspeed_40m:
            try await prefetchData(raw: .wind_speed_40m, time: time)
        case  .windspeed_80m:
            try await prefetchData(raw: .wind_speed_80m, time: time)
        case  .windspeed_120m:
            try await prefetchData(raw: .wind_speed_120m, time: time)
        case .winddirection_10m:
            try await prefetchData(raw: .wind_direction_10m, time: time)
        case  .winddirection_40m:
            try await prefetchData(raw: .wind_direction_40m, time: time)
        case  .winddirection_80m:
            try await prefetchData(raw: .wind_direction_80m, time: time)
        case  .winddirection_120m:
            try await prefetchData(raw: .wind_direction_120m, time: time)
        case .vapor_pressure_deficit, .vapour_pressure_deficit:
            try await prefetchData(raw: .temperature_2m, time: time)
            try await prefetchData(raw: .relative_humidity_2m, time: time)
        case .et0_fao_evapotranspiration:
            try await prefetchData(raw: .shortwave_radiation, time: time)
            try await prefetchData(raw: .temperature_2m, time: time)
            try await prefetchData(raw: .relative_humidity_2m, time: time)
            try await prefetchData(raw: .wind_speed_10m, time: time)
        case .surface_pressure:
            try await prefetchData(raw: .pressure_msl, time: time)
            try await prefetchData(raw: .temperature_2m, time: time)
        case .terrestrial_radiation, .terrestrial_radiation_instant:
            break
        case .dew_point_2m, .dewpoint_2m:
            try await prefetchData(raw: .temperature_2m, time: time)
            try await prefetchData(raw: .relative_humidity_2m, time: time)
        case .direct_normal_irradiance, .direct_normal_irradiance_instant:
            try await prefetchData(raw: .direct_radiation, time: time)
        case .shortwave_radiation_instant:
            try await prefetchData(raw: .shortwave_radiation, time: time)
        case .global_tilted_irradiance, .global_tilted_irradiance_instant, .diffuse_radiation, .diffuse_radiation_instant:
            try await prefetchData(raw: .shortwave_radiation, time: time)
            try await prefetchData(raw: .direct_radiation, time: time)
        case .weathercode:
            try await prefetchData(raw: .weather_code, time: time)
        case .is_day:
            break
        case .wet_bulb_temperature_2m:
            try await prefetchData(raw: .temperature_2m, time: time)
            try await prefetchData(raw: .relative_humidity_2m, time: time)
        case .cloudcover:
            try await prefetchData(raw: .cloud_cover, time: time)
        case .cloudcover_low:
            try await prefetchData(raw: .cloud_cover_low, time: time)
        case .cloudcover_mid:
            try await prefetchData(raw: .cloud_cover_mid, time: time)
        case .cloudcover_high:
            try await prefetchData(raw: .cloud_cover_high, time: time)
        case .windgusts_10m:
            try await prefetchData(raw: .wind_gusts_10m, time: time)
        case .sunshine_duration:
            try await prefetchData(raw: .direct_radiation, time: time)
        case .rain:
            try await prefetchData(raw: .precipitation, time: time)
            try await prefetchData(raw: .showers, time: time)
            try await prefetchData(raw: .snowfall_water_equivalent, time: time)
        case .direct_radiation_instant:
            try await prefetchData(raw: .direct_radiation, time: time)
        case .snowfall:
            try await prefetchData(raw: .snowfall_water_equivalent, time: time)
        case .soil_temperature_10_to_45cm:
            try await prefetchData(raw: .soil_temperature_10_to_35cm, time: time)
        case .soil_temperature_40_to_100cm:
            try await prefetchData(raw: .soil_temperature_35_to_100cm, time: time)
        case .soil_temperature_100_to_200cm:
            try await prefetchData(raw: .soil_temperature_100_to_300cm, time: time)
        case .soil_moisture_10_to_40cm:
            try await prefetchData(raw: .soil_moisture_10_to_35cm, time: time)
        case .soil_moisture_40_to_100cm:
            try await prefetchData(raw: .soil_moisture_35_to_100cm, time: time)
        case .soil_moisture_100_to_200cm:
            try await prefetchData(raw: .soil_moisture_100_to_300cm, time: time)
        }
    }

    func get(derived: BomVariableDerived, time: TimerangeDtAndSettings) async throws -> DataAndUnit {
        switch derived {
        case .windspeed_10m:
            return try await get(raw: .wind_speed_10m, time: time)
        case .windspeed_40m:
            return try await get(raw: .wind_speed_40m, time: time)
        case .windspeed_80m:
            return try await get(raw: .wind_speed_80m, time: time)
        case .windspeed_120m:
            return try await get(raw: .wind_speed_120m, time: time)
        case .winddirection_10m:
            return try await get(raw: .wind_direction_10m, time: time)
        case .winddirection_40m:
            return try await get(raw: .wind_direction_40m, time: time)
        case .winddirection_80m:
            return try await get(raw: .wind_direction_80m, time: time)
        case .winddirection_120m:
            return try await get(raw: .wind_direction_120m, time: time)
        case .apparent_temperature:
            let windspeed = try await get(raw: .wind_speed_10m, time: time).data
            let temperature = try await get(raw: .temperature_2m, time: time).data
            let relhum = try await get(raw: .relative_humidity_2m, time: time).data
            let radiation = try await get(raw: .shortwave_radiation, time: time).data
            return DataAndUnit(Meteorology.apparentTemperature(temperature_2m: temperature, relativehumidity_2m: relhum, windspeed_10m: windspeed, shortwave_radiation: radiation), .celsius)
        case .vapor_pressure_deficit, .vapour_pressure_deficit:
            let temperature = try await get(raw: .temperature_2m, time: time).data
            let rh = try await get(raw: .relative_humidity_2m, time: time).data
            let dewpoint = zip(temperature, rh).map(Meteorology.dewpoint)
            return DataAndUnit(zip(temperature, dewpoint).map(Meteorology.vaporPressureDeficit), .kilopascal)
        case .et0_fao_evapotranspiration:
            let exrad = Zensun.extraTerrestrialRadiationBackwards(latitude: reader.modelLat, longitude: reader.modelLon, timerange: time.time)
            let swrad = try await get(raw: .shortwave_radiation, time: time).data
            let temperature = try await get(raw: .temperature_2m, time: time).data
            let windspeed = try await get(raw: .wind_speed_10m, time: time).data
            let rh = try await get(raw: .relative_humidity_2m, time: time).data
            let dewpoint = zip(temperature, rh).map(Meteorology.dewpoint)
            let et0 = swrad.indices.map { i in
                return Meteorology.et0Evapotranspiration(temperature2mCelsius: temperature[i], windspeed10mMeterPerSecond: windspeed[i], dewpointCelsius: dewpoint[i], shortwaveRadiationWatts: swrad[i], elevation: reader.targetElevation, extraTerrestrialRadiation: exrad[i], dtSeconds: 3600)
            }
            return DataAndUnit(et0, .millimetre)
        case .relativehumidity_2m:
            return try await get(raw: .relative_humidity_2m, time: time)
        case .surface_pressure:
            let temperature = try await get(raw: .temperature_2m, time: time).data
            let pressure = try await get(raw: .pressure_msl, time: time)
            return DataAndUnit(Meteorology.surfacePressure(temperature: temperature, pressure: pressure.data, elevation: reader.targetElevation), pressure.unit)
        case .terrestrial_radiation:
            /// Use center averaged
            let solar = Zensun.extraTerrestrialRadiationBackwards(latitude: reader.modelLat, longitude: reader.modelLon, timerange: time.time)
            return DataAndUnit(solar, .wattPerSquareMetre)
        case .terrestrial_radiation_instant:
            /// Use center averaged
            let solar = Zensun.extraTerrestrialRadiationInstant(latitude: reader.modelLat, longitude: reader.modelLon, timerange: time.time)
            return DataAndUnit(solar, .wattPerSquareMetre)
        case .dewpoint_2m, .dew_point_2m:
            let temperature = try await get(raw: .temperature_2m, time: time)
            let rh = try await get(raw: .relative_humidity_2m, time: time)
            return DataAndUnit(zip(temperature.data, rh.data).map(Meteorology.dewpoint), temperature.unit)
        case .shortwave_radiation_instant:
            let sw = try await get(raw: .shortwave_radiation, time: time)
            let factor = Zensun.backwardsAveragedToInstantFactor(time: time.time, latitude: reader.modelLat, longitude: reader.modelLon)
            return DataAndUnit(zip(sw.data, factor).map(*), sw.unit)
        case .direct_normal_irradiance:
            let dhi = try await get(raw: .direct_radiation, time: time).data
            let dni = Zensun.calculateBackwardsDNI(directRadiation: dhi, latitude: reader.modelLat, longitude: reader.modelLon, timerange: time.time)
            return DataAndUnit(dni, .wattPerSquareMetre)
        case .direct_normal_irradiance_instant:
            let direct = try await get(raw: .direct_radiation, time: time)
            let dni = Zensun.calculateBackwardsDNI(directRadiation: direct.data, latitude: reader.modelLat, longitude: reader.modelLon, timerange: time.time, convertToInstant: true)
            return DataAndUnit(dni, direct.unit)
        case .diffuse_radiation:
            let swrad = try await get(raw: .shortwave_radiation, time: time)
            let dhi = try await get(raw: .direct_radiation, time: time)
            return DataAndUnit(zip(swrad.data, dhi.data).map(-), swrad.unit)
        case .direct_radiation_instant:
            let direct = try await get(raw: .direct_radiation, time: time)
            let factor = Zensun.backwardsAveragedToInstantFactor(time: time.time, latitude: reader.modelLat, longitude: reader.modelLon)
            return DataAndUnit(zip(direct.data, factor).map(*), direct.unit)
        case .diffuse_radiation_instant:
            let diff = try await get(derived: .diffuse_radiation, time: time)
            let factor = Zensun.backwardsAveragedToInstantFactor(time: time.time, latitude: reader.modelLat, longitude: reader.modelLon)
            return DataAndUnit(zip(diff.data, factor).map(*), diff.unit)
        case .weathercode:
            return try await get(raw: .weather_code, time: time)
        case .is_day:
            return DataAndUnit(Zensun.calculateIsDay(timeRange: time.time, lat: reader.modelLat, lon: reader.modelLon), .dimensionlessInteger)
        case .wet_bulb_temperature_2m:
            let temperature = try await get(raw: .temperature_2m, time: time)
            let rh = try await get(raw: .relative_humidity_2m, time: time)
            return DataAndUnit(zip(temperature.data, rh.data).map(Meteorology.wetBulbTemperature), temperature.unit)
        case .cloudcover:
            return try await get(raw: .cloud_cover, time: time)
        case .cloudcover_low:
            return try await get(raw: .cloud_cover_low, time: time)
        case .cloudcover_mid:
            return try await get(raw: .cloud_cover_mid, time: time)
        case .cloudcover_high:
            return try await get(raw: .cloud_cover_high, time: time)
        case .windgusts_10m:
            return try await get(raw: .wind_gusts_10m, time: time)
        case .sunshine_duration:
            let directRadiation = try await get(raw: .direct_radiation, time: time)
            let duration = Zensun.calculateBackwardsSunshineDuration(directRadiation: directRadiation.data, latitude: reader.modelLat, longitude: reader.modelLon, timerange: time.time)
            return DataAndUnit(duration, .seconds)
        case .rain:
            let precipitation = try await get(raw: .precipitation, time: time)
            let showers = try await get(raw: .showers, time: time)
            let snoweq = try await get(raw: .snowfall_water_equivalent, time: time)
            return DataAndUnit(zip(precipitation.data, zip(snoweq.data, showers.data)).map({ max($0 - $1.0 - $1.1, 0) }), precipitation.unit)
        case .snowfall:
            let snoweq = try await get(raw: .snowfall_water_equivalent, time: time)
            return DataAndUnit(snoweq.data.map { $0 * 0.7 }, .centimetre)
        case .soil_temperature_10_to_45cm:
            return try await get(raw: .soil_temperature_10_to_35cm, time: time)
        case .soil_temperature_40_to_100cm:
            return try await get(raw: .soil_temperature_35_to_100cm, time: time)
        case .soil_temperature_100_to_200cm:
            return try await get(raw: .soil_temperature_100_to_300cm, time: time)
        case .soil_moisture_10_to_40cm:
            return try await get(raw: .soil_moisture_10_to_35cm, time: time)
        case .soil_moisture_40_to_100cm:
            return try await get(raw: .soil_moisture_35_to_100cm, time: time)
        case .soil_moisture_100_to_200cm:
            return try await get(raw: .soil_moisture_100_to_300cm, time: time)
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

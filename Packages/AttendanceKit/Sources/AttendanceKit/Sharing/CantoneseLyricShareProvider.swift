import Foundation

public enum AttendanceShareMoment: String, Equatable, Sendable {
    case clockIn
    case clockOut
}

public enum CantoneseTimePeriod: String, Equatable, Sendable {
    case lateNight = "深夜"
    case morning = "朝早"
    case daytime = "日間"
    case evening = "傍晚"
    case night = "夜晚"
}

public enum TraditionalFestival: String, Equatable, Hashable, Sendable {
    case lunarNewYear = "農曆新年"
    case lanternFestival = "元宵節"
    case dragonBoatFestival = "端午節"
    case qixiFestival = "七夕"
    case midAutumnFestival = "中秋節"
    case doubleNinthFestival = "重陽節"
    case labaFestival = "臘八節"
    case littleNewYear = "小年"
    case lunarNewYearsEve = "年三十"
}

public enum SolarTerm: String, CaseIterable, Equatable, Hashable, Sendable {
    case minorCold = "小寒"
    case majorCold = "大寒"
    case startOfSpring = "立春"
    case rainWater = "雨水"
    case awakeningOfInsects = "驚蟄"
    case springEquinox = "春分"
    case clearAndBright = "清明"
    case grainRain = "穀雨"
    case startOfSummer = "立夏"
    case grainFull = "小滿"
    case grainInEar = "芒種"
    case summerSolstice = "夏至"
    case minorHeat = "小暑"
    case majorHeat = "大暑"
    case startOfAutumn = "立秋"
    case limitOfHeat = "處暑"
    case whiteDew = "白露"
    case autumnEquinox = "秋分"
    case coldDew = "寒露"
    case frostDescent = "霜降"
    case startOfWinter = "立冬"
    case minorSnow = "小雪"
    case majorSnow = "大雪"
    case winterSolstice = "冬至"
}

public enum CantoneseLyricOccasion: Equatable, Sendable {
    case traditionalFestival(TraditionalFestival)
    case solarTerm(SolarTerm)

    public var label: String {
        switch self {
        case .traditionalFestival(let festival):
            return "傳統節日 · \(festival.rawValue)"
        case .solarTerm(let term):
            return "節氣 · \(term.rawValue)"
        }
    }
}

public struct CantoneseLyricExcerpt: Equatable, Sendable {
    public let line: String
    public let songTitle: String
    public let artist: String

    public init(line: String, songTitle: String, artist: String) {
        self.line = line
        self.songTitle = songTitle
        self.artist = artist
    }

    public var appleMusicSearchURL: URL? {
        appleMusicSearchURL(scheme: "music")
    }

    public var appleMusicWebSearchURL: URL? {
        appleMusicSearchURL(scheme: "https")
    }

    private func appleMusicSearchURL(scheme: String) -> URL? {
        var components = URLComponents()
        components.scheme = scheme
        components.host = "music.apple.com"
        components.path = "/hk/search"
        components.queryItems = [
            URLQueryItem(name: "term", value: "\(songTitle) \(artist)")
        ]
        return components.url
    }
}

public struct CantoneseLyricShare: Equatable, Sendable {
    public let moment: AttendanceShareMoment
    public let timePeriod: CantoneseTimePeriod
    public let occasion: CantoneseLyricOccasion
    public let excerpt: CantoneseLyricExcerpt
    public let timestampLabel: String

    public var momentLabel: String {
        let action = moment == .clockIn ? "返工" : "收工"
        return timePeriod.rawValue + action
    }

    public var shareTitle: String {
        "\(occasion.label) · \(momentLabel)"
    }

    public var shareText: String {
        let hashtag = moment == .clockIn ? "#返工打卡" : "#收工打卡"
        return """
        \(timestampLabel) · \(occasion.label) · \(momentLabel)
        「\(excerpt.line)」
        《\(excerpt.songTitle)》 · \(excerpt.artist)
        \(hashtag) #粵語歌
        """
    }
}

public struct CantoneseLyricShareProvider: Sendable {
    public let timeZone: TimeZone

    private let gregorianCalendar: Calendar
    private let chineseCalendar: Calendar

    public init(timeZone: TimeZone = .current) {
        self.timeZone = timeZone

        var gregorianCalendar = Calendar(identifier: .gregorian)
        gregorianCalendar.timeZone = timeZone
        gregorianCalendar.locale = Locale(identifier: "en_US_POSIX")
        self.gregorianCalendar = gregorianCalendar

        var chineseCalendar = Calendar(identifier: .chinese)
        chineseCalendar.timeZone = timeZone
        self.chineseCalendar = chineseCalendar
    }

    public func share(
        for date: Date,
        moment: AttendanceShareMoment,
        variation: Int = 0
    ) -> CantoneseLyricShare {
        let period = timePeriod(for: date)
        let occasion: CantoneseLyricOccasion
        let excerpt: CantoneseLyricExcerpt

        if let festival = traditionalFestival(on: date) {
            occasion = .traditionalFestival(festival)
            let pair = Self.festivalLyrics[festival] ?? Self.defaultLyrics
            excerpt = moment == .clockIn ? pair.clockIn : pair.clockOut
        } else {
            let term = solarTerm(containing: date)
            occasion = .solarTerm(term)
            let candidates = Self.rotatingLyrics(for: term, moment: moment)
            let dayIndex = gregorianCalendar.ordinality(of: .day, in: .era, for: date) ?? 0
            let index = (dayIndex + max(variation, 0)) % candidates.count
            excerpt = candidates[index]
        }

        return CantoneseLyricShare(
            moment: moment,
            timePeriod: period,
            occasion: occasion,
            excerpt: excerpt,
            timestampLabel: timestampLabel(for: date)
        )
    }

    public func timePeriod(for date: Date) -> CantoneseTimePeriod {
        switch gregorianCalendar.component(.hour, from: date) {
        case 5..<11: .morning
        case 11..<17: .daytime
        case 17..<22: .evening
        case 22...23: .night
        default: .lateNight
        }
    }

    public func traditionalFestival(on date: Date) -> TraditionalFestival? {
        let components = chineseCalendar.dateComponents([.month, .day, .isLeapMonth], from: date)
        guard components.isLeapMonth != true,
              let month = components.month,
              let day = components.day else {
            return nil
        }

        switch (month, day) {
        case (1, 1): return .lunarNewYear
        case (1, 15): return .lanternFestival
        case (5, 5): return .dragonBoatFestival
        case (7, 7): return .qixiFestival
        case (8, 15): return .midAutumnFestival
        case (9, 9): return .doubleNinthFestival
        case (12, 8): return .labaFestival
        case (12, 23): return .littleNewYear
        default: break
        }

        guard let tomorrow = gregorianCalendar.date(byAdding: .day, value: 1, to: date) else {
            return nil
        }
        let tomorrowComponents = chineseCalendar.dateComponents([.month, .day], from: tomorrow)
        if tomorrowComponents.month == 1, tomorrowComponents.day == 1 {
            return .lunarNewYearsEve
        }
        return nil
    }

    public func solarTerm(containing date: Date) -> SolarTerm {
        let month = gregorianCalendar.component(.month, from: date)
        let day = gregorianCalendar.component(.day, from: date)

        return Self.solarTermBoundaries.last {
            month > $0.month || (month == $0.month && day >= $0.day)
        }?.term ?? .winterSolstice
    }

    private func timestampLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = gregorianCalendar
        formatter.timeZone = timeZone
        formatter.locale = Locale(identifier: "zh_HK")
        formatter.setLocalizedDateFormatFromTemplate("MMMdHm")
        return formatter.string(from: date)
    }

    static var allExcerpts: [CantoneseLyricExcerpt] {
        let pairs = [Self.defaultLyrics]
            + Array(Self.festivalLyrics.values)
            + Array(Self.solarTermLyrics.values)
        return pairs.flatMap { [$0.clockIn, $0.clockOut] }
    }
}

private extension CantoneseLyricShareProvider {
    struct SolarTermBoundary: Sendable {
        let month: Int
        let day: Int
        let term: SolarTerm
    }

    struct LyricPair: Sendable {
        let clockIn: CantoneseLyricExcerpt
        let clockOut: CantoneseLyricExcerpt
    }

    static let solarTermBoundaries: [SolarTermBoundary] = [
        .init(month: 1, day: 5, term: .minorCold),
        .init(month: 1, day: 20, term: .majorCold),
        .init(month: 2, day: 4, term: .startOfSpring),
        .init(month: 2, day: 19, term: .rainWater),
        .init(month: 3, day: 5, term: .awakeningOfInsects),
        .init(month: 3, day: 20, term: .springEquinox),
        .init(month: 4, day: 4, term: .clearAndBright),
        .init(month: 4, day: 20, term: .grainRain),
        .init(month: 5, day: 5, term: .startOfSummer),
        .init(month: 5, day: 21, term: .grainFull),
        .init(month: 6, day: 5, term: .grainInEar),
        .init(month: 6, day: 21, term: .summerSolstice),
        .init(month: 7, day: 7, term: .minorHeat),
        .init(month: 7, day: 23, term: .majorHeat),
        .init(month: 8, day: 7, term: .startOfAutumn),
        .init(month: 8, day: 23, term: .limitOfHeat),
        .init(month: 9, day: 7, term: .whiteDew),
        .init(month: 9, day: 23, term: .autumnEquinox),
        .init(month: 10, day: 8, term: .coldDew),
        .init(month: 10, day: 23, term: .frostDescent),
        .init(month: 11, day: 7, term: .startOfWinter),
        .init(month: 11, day: 22, term: .minorSnow),
        .init(month: 12, day: 7, term: .majorSnow),
        .init(month: 12, day: 21, term: .winterSolstice)
    ]

    static let redSun = CantoneseLyricExcerpt(
        line: "命運就算顛沛流離",
        songTitle: "紅日",
        artist: "李克勤"
    )
    static let brave = CantoneseLyricExcerpt(
        line: "沿途紅燈再紅，無人可擋我路",
        songTitle: "勇",
        artist: "楊千嬅"
    )
    static let gloriousYears = CantoneseLyricExcerpt(
        line: "風雨中抱緊自由",
        songTitle: "光輝歲月",
        artist: "Beyond"
    )
    static let trueMan = CantoneseLyricExcerpt(
        line: "成和敗努力嘗試",
        songTitle: "真的漢子",
        artist: "林子祥"
    )
    static let freedom = CantoneseLyricExcerpt(
        line: "仍然自由自我，永遠高唱我歌",
        songTitle: "海闊天空",
        artist: "Beyond"
    )
    static let workingClass = CantoneseLyricExcerpt(
        line: "我哋呢班打工仔",
        songTitle: "半斤八兩",
        artist: "許冠傑"
    )
    static let pride = CantoneseLyricExcerpt(
        line: "Pride in your eyes，為我改寫下半生",
        songTitle: "我的驕傲",
        artist: "容祖兒"
    )
    static let sunset = CantoneseLyricExcerpt(
        line: "夕陽無限好，天色已黃昏",
        songTitle: "夕陽無限好",
        artist: "陳奕迅"
    )
    static let yearsAsSong = CantoneseLyricExcerpt(
        line: "天氣不似預期，但要走總要飛",
        songTitle: "歲月如歌",
        artist: "陳奕迅"
    )
    static let joyStreet = CantoneseLyricExcerpt(
        line: "忘掉種過的花，重新的出發",
        songTitle: "囍帖街",
        artist: "謝安琪"
    )
    static let resonance = CantoneseLyricExcerpt(
        line: "夜闌靜，問有誰共鳴",
        songTitle: "有誰共鳴",
        artist: "張國榮"
    )
    static let thousandSongs = CantoneseLyricExcerpt(
        line: "來日縱使千千闋歌，飄於遠方我路上",
        songTitle: "千千闋歌",
        artist: "陳慧嫻"
    )
    static let wanderersHeart = CantoneseLyricExcerpt(
        line: "命裡有時終須有，命裡無時莫強求",
        songTitle: "浪子心聲",
        artist: "許冠傑"
    )
    static let snow = CantoneseLyricExcerpt(
        line: "又見雪飄過，飄於傷心記憶中",
        songTitle: "飄雪",
        artist: "陳慧嫻"
    )
    static let moon = CantoneseLyricExcerpt(
        line: "仍然倚在失眠夜，望天邊星宿",
        songTitle: "月半小夜曲",
        artist: "李克勤"
    )
    static let spring = CantoneseLyricExcerpt(
        line: "春天該很好，你若尚在場",
        songTitle: "春夏秋冬",
        artist: "張國榮"
    )
    static let summer = CantoneseLyricExcerpt(
        line: "夏天該很好，你若尚在場",
        songTitle: "春夏秋冬",
        artist: "張國榮"
    )
    static let autumn = CantoneseLyricExcerpt(
        line: "秋天該很好，你若尚在場",
        songTitle: "春夏秋冬",
        artist: "張國榮"
    )
    static let winter = CantoneseLyricExcerpt(
        line: "冬天該很好，你若尚在場",
        songTitle: "春夏秋冬",
        artist: "張國榮"
    )
    static let rain = CantoneseLyricExcerpt(
        line: "留戀於夜幕，雨中一角",
        songTitle: "雨夜的浪漫",
        artist: "譚詠麟"
    )
    static let summerRomance = CantoneseLyricExcerpt(
        line: "是你嗎，手執鮮花的一個",
        songTitle: "夏日傾情",
        artist: "黎明"
    )
    static let grapes = CantoneseLyricExcerpt(
        line: "誰都心酸過，哪個沒有",
        songTitle: "葡萄成熟時",
        artist: "陳奕迅"
    )
    static let fuji = CantoneseLyricExcerpt(
        line: "攔路雨偏似雪花，飲泣的你凍嗎",
        songTitle: "富士山下",
        artist: "陳奕迅"
    )
    static let remoteHer = CantoneseLyricExcerpt(
        line: "讓晚風輕輕吹送了落霞",
        songTitle: "遙遠的她",
        artist: "張學友"
    )
    static let blessing = CantoneseLyricExcerpt(
        line: "祝福你，在每一天裡永遠多采多姿",
        songTitle: "祝福你",
        artist: "甄妮"
    )
    static let godOfWealth = CantoneseLyricExcerpt(
        line: "財神到，財神到，好心得好報",
        songTitle: "財神到",
        artist: "許冠傑"
    )
    static let dailyLove = CantoneseLyricExcerpt(
        line: "每一天也在這心裡，愛你多一些",
        songTitle: "每天愛你多一些",
        artist: "張學友"
    )
    static let promise = CantoneseLyricExcerpt(
        line: "忘掉天地，彷彿也想不起自己",
        songTitle: "約定",
        artist: "王菲"
    )
    static let greatWall = CantoneseLyricExcerpt(
        line: "遙遠的東方，遼闊的邊疆",
        songTitle: "長城",
        artist: "Beyond"
    )

    static let defaultLyrics = LyricPair(clockIn: workingClass, clockOut: sunset)

    static let festivalLyrics: [TraditionalFestival: LyricPair] = [
        .lunarNewYear: .init(clockIn: blessing, clockOut: godOfWealth),
        .lanternFestival: .init(clockIn: dailyLove, clockOut: moon),
        .dragonBoatFestival: .init(clockIn: greatWall, clockOut: freedom),
        .qixiFestival: .init(clockIn: dailyLove, clockOut: promise),
        .midAutumnFestival: .init(clockIn: pride, clockOut: moon),
        .doubleNinthFestival: .init(clockIn: trueMan, clockOut: yearsAsSong),
        .labaFestival: .init(clockIn: blessing, clockOut: remoteHer),
        .littleNewYear: .init(clockIn: blessing, clockOut: godOfWealth),
        .lunarNewYearsEve: .init(clockIn: redSun, clockOut: thousandSongs)
    ]

    static let solarTermLyrics: [SolarTerm: LyricPair] = [
        .minorCold: .init(clockIn: redSun, clockOut: snow),
        .majorCold: .init(clockIn: gloriousYears, clockOut: moon),
        .startOfSpring: .init(clockIn: brave, clockOut: spring),
        .rainWater: .init(clockIn: redSun, clockOut: rain),
        .awakeningOfInsects: .init(clockIn: trueMan, clockOut: yearsAsSong),
        .springEquinox: .init(clockIn: freedom, clockOut: spring),
        .clearAndBright: .init(clockIn: gloriousYears, clockOut: fuji),
        .grainRain: .init(clockIn: brave, clockOut: rain),
        .startOfSummer: .init(clockIn: redSun, clockOut: summerRomance),
        .grainFull: .init(clockIn: pride, clockOut: grapes),
        .grainInEar: .init(clockIn: trueMan, clockOut: joyStreet),
        .summerSolstice: .init(clockIn: freedom, clockOut: summer),
        .minorHeat: .init(clockIn: workingClass, clockOut: sunset),
        .majorHeat: .init(clockIn: redSun, clockOut: freedom),
        .startOfAutumn: .init(clockIn: brave, clockOut: autumn),
        .limitOfHeat: .init(clockIn: trueMan, clockOut: joyStreet),
        .whiteDew: .init(clockIn: pride, clockOut: remoteHer),
        .autumnEquinox: .init(clockIn: gloriousYears, clockOut: resonance),
        .coldDew: .init(clockIn: redSun, clockOut: yearsAsSong),
        .frostDescent: .init(clockIn: freedom, clockOut: gloriousYears),
        .startOfWinter: .init(clockIn: trueMan, clockOut: winter),
        .minorSnow: .init(clockIn: brave, clockOut: snow),
        .majorSnow: .init(clockIn: gloriousYears, clockOut: moon),
        .winterSolstice: .init(clockIn: redSun, clockOut: wanderersHeart)
    ]

    static func rotatingLyrics(
        for term: SolarTerm,
        moment: AttendanceShareMoment
    ) -> [CantoneseLyricExcerpt] {
        let contextualPair = solarTermLyrics[term] ?? defaultLyrics
        let seasonalPool: [CantoneseLyricExcerpt]

        switch (season(for: term), moment) {
        case (.spring, .clockIn):
            seasonalPool = [brave, redSun, trueMan, freedom, pride, spring, rain]
        case (.spring, .clockOut):
            seasonalPool = [spring, rain, yearsAsSong, joyStreet, remoteHer, resonance, thousandSongs]
        case (.summer, .clockIn):
            seasonalPool = [redSun, freedom, trueMan, pride, workingClass, brave, summerRomance]
        case (.summer, .clockOut):
            seasonalPool = [summer, summerRomance, sunset, grapes, remoteHer, yearsAsSong, joyStreet]
        case (.autumn, .clockIn):
            seasonalPool = [brave, gloriousYears, trueMan, pride, redSun, freedom, workingClass]
        case (.autumn, .clockOut):
            seasonalPool = [autumn, grapes, remoteHer, resonance, thousandSongs, yearsAsSong, sunset]
        case (.winter, .clockIn):
            seasonalPool = [redSun, gloriousYears, brave, trueMan, freedom, pride, workingClass]
        case (.winter, .clockOut):
            seasonalPool = [winter, snow, moon, wanderersHeart, resonance, thousandSongs, fuji]
        }

        let contextual = moment == .clockIn ? contextualPair.clockIn : contextualPair.clockOut
        return [contextual] + seasonalPool.filter { $0 != contextual }
    }

    static func season(for term: SolarTerm) -> LyricSeason {
        switch term {
        case .startOfSpring, .rainWater, .awakeningOfInsects,
             .springEquinox, .clearAndBright, .grainRain:
            return .spring
        case .startOfSummer, .grainFull, .grainInEar,
             .summerSolstice, .minorHeat, .majorHeat:
            return .summer
        case .startOfAutumn, .limitOfHeat, .whiteDew,
             .autumnEquinox, .coldDew, .frostDescent:
            return .autumn
        case .startOfWinter, .minorSnow, .majorSnow,
             .winterSolstice, .minorCold, .majorCold:
            return .winter
        }
    }

    enum LyricSeason {
        case spring
        case summer
        case autumn
        case winter
    }
}

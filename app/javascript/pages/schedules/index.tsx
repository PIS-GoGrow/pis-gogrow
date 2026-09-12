const [selectedDate, setSelectedDate] = useState(days[0]?.date)
const [selections, setSelections] = useState<Record<string, Record<number, number>>>({})
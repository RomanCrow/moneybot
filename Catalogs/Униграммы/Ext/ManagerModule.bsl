﻿#Область ПрограммныйИнтерфейс

Процедура ДобавитьУниграммыВСловарь(Строка) Экспорт
	
	РазборСтроки = ПолучитьРазборСтроки(Строка);
	
	Униграмма = РазборСтроки.ВыгрузитьКолонку("Униграмма");
	
	Запрос = Новый Запрос;
	Запрос.УстановитьПараметр("Униграмма", Униграмма);
	Запрос.Текст = 
	"ВЫБРАТЬ
	|	Униграммы.Наименование КАК Наименование,
	|	Униграммы.Ссылка КАК Ссылка
	|ИЗ
	|	Справочник.Униграммы КАК Униграммы
	|ГДЕ
	|	Униграммы.Наименование В(&Униграмма)";
	
	Выгрузка = Запрос.Выполнить().Выгрузить();
	Отбор = Новый Структура("Наименование");
	
	Для каждого СтрокаРазбора Из РазборСтроки Цикл
		Отбор.Наименование = СтрокаРазбора.Униграмма;
		НайденныеСтроки = Выгрузка.НайтиСтроки(Отбор);
		Если НайденныеСтроки.Количество() = 0 Тогда
			НовЭлемент = Справочники.Униграммы.СоздатьЭлемент();
			НовЭлемент.Наименование = СтрокаРазбора.Униграмма;
			НовЭлемент.Метафон = СтрокаРазбора.Метафон;
			Если Не ЗначениеЗаполнено(НовЭлемент.Метафон) Тогда
				НовЭлемент.Метафон = ВРег(СтрокаРазбора.Униграмма);
			КонецЕсли; 
			НовЭлемент.Записать();
		КонецЕсли; 		
	КонецЦикла; 
	
КонецПроцедуры

Функция НайтиУниграммы(Униграмма, Параметры = Неопределено) Экспорт
	
	Результат = Новый Массив;
	
	АнализПоМетафонам = Истина;
	Если Параметры <> Неопределено Тогда	
		Параметры.Свойство("АнализПоМетафонам", АнализПоМетафонам);
	КонецЕсли; 
	
	Метафоны = Новый Массив;
	Для каждого Слово Из Униграмма Цикл
		Метафон = Metaphone(Слово);
		Если Не ЗначениеЗаполнено(Метафон) Тогда
			Метафон = ВРег(Слово);
		КонецЕсли;               
		Метафоны.Добавить(Метафон);
	КонецЦикла; 
	
	Запрос = Новый Запрос;
	Запрос.УстановитьПараметр("АнализПоМетафонам", АнализПоМетафонам);
	Запрос.УстановитьПараметр("Униграмма", Униграмма);
	Запрос.УстановитьПараметр("Метафоны", Метафоны);
	Запрос.Текст = 
	"ВЫБРАТЬ
	|	МАКСИМУМ(Униграммы.Ссылка) КАК Ссылка,
	|	Униграммы.Метафон КАК Метафон
	|ПОМЕСТИТЬ ВТ_Униграммы
	|ИЗ
	|	Справочник.Униграммы КАК Униграммы
	|ГДЕ
	|	ВЫБОР
	|			КОГДА &АнализПоМетафонам
	|				ТОГДА Униграммы.Метафон В (&Метафоны)
	|			ИНАЧЕ Униграммы.Наименование В (&Униграмма)
	|		КОНЕЦ
	|
	|СГРУППИРОВАТЬ ПО
	|	Униграммы.Метафон
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|ВЫБРАТЬ
	|	ВТ_Униграммы.Ссылка КАК Ссылка
	|ИЗ
	|	ВТ_Униграммы КАК ВТ_Униграммы
	|		ВНУТРЕННЕЕ СОЕДИНЕНИЕ Справочник.Униграммы КАК Униграммы
	|		ПО ВТ_Униграммы.Ссылка = Униграммы.Ссылка";
	
	РезультатЗапроса = Запрос.Выполнить();
	Если Не РезультатЗапроса.Пустой() Тогда
		Выборка = РезультатЗапроса.Выбрать();
		Пока Выборка.Следующий() Цикл
			Результат.Добавить(Выборка.Ссылка);	
		КонецЦикла; 
	КонецЕсли; 
	
	Возврат Результат; 
	
КонецФункции

Функция ПолучитьУниграммуСтроки(Знач Строка) Экспорт
	
	Строка = УбратьЧислаЗнакиПрипинанияИОператорыИзСтроки(Строка);
	
	Униграмма = СтрРазделить(Строка, " ", Ложь);
	Индекс = 0;
	Для каждого Слово Из Униграмма Цикл
		
		Униграмма[Индекс] = ПолучитьСтем(Слово);
		Индекс = Индекс + 1;
		
	КонецЦикла; 
	
	Возврат Униграмма;
	
КонецФункции

Процедура ДобавитьУниграммыИзФайлаОбученияНейроннойСети(НейроннаяСеть) Экспорт
	
	ДД = НейроннаяСеть.ПолучитьОбъект().ДанныеОбучения.Получить();
	
	Если ДД = Неопределено Тогда
		Сообщить("У нейронной сети " + НейроннаяСеть + " не заполнен файл обучения!");
		Возврат;
	КонецЕсли; 
	
	ИмяФайла = ПолучитьИмяВременногоФайла("tmp");
	ДД.Записать(ИмяФайла);
	
	ТекДок = Новый ТекстовыйДокумент;
	ТекДок.Прочитать(ИмяФайла, КодировкаТекста.UTF8);
	
	КоличествоСтрок = ТекДок.КоличествоСтрок();
	
	Для Индекс = 3 По КоличествоСтрок Цикл
		ТекСтрока = ТекДок.ПолучитьСтроку(Индекс);
		Если СтрНайти(ТекСтрока, "--------") <> 0 Или СтрНайти(ТекСтрока, "++++++++") <> 0 Тогда
			Продолжить;
		КонецЕсли; 
		Справочники.Униграммы.ДобавитьУниграммыВСловарь(ТекСтрока);
	КонецЦикла; 
	
КонецПроцедуры

Функция ПолучитьРазборСтроки(Знач Строка) Экспорт
	
	Результат = Новый ТаблицаЗначений;
	Результат.Колонки.Добавить("Униграмма");
	Результат.Колонки.Добавить("Метафон");
	
	Униграмма = ПолучитьУниграммуСтроки(Строка);
	
	Для каждого Слово Из Униграмма Цикл
		
		НоваяСтрока = Результат.Добавить();
		НоваяСтрока.Униграмма = Слово;
		НоваяСтрока.Метафон = Metaphone(Слово);
		
	КонецЦикла;
	
	Возврат Результат;
		
КонецФункции
 

#КонецОбласти

#Область СлужебныеПроцедурыИФункции

Процедура ПолучитьПозиции(Строка, РВ, Р1, Р2)

	РВ	= 0;
	Р1	= 0;
	Р2	= 0;
	
	Гласные	= "аеиоуыэюя";
	
	//Определение РВ
	Длина	= СтрДлина(Строка);
	Для Сч = 1 По Длина - 1 Цикл
		Символ	= Сред(Строка,Сч,1);
		Если Найти(Гласные, Символ) > 0 Тогда
			РВ	= Сч + 1;
			Прервать;
		КонецЕсли;
	КонецЦикла;
	Если РВ = 0 Тогда
		Возврат;
	КонецЕсли;
	//Определение Р1
	СтрокаРВ= Сред(Строка, РВ);
	Длина	= СтрДлина(СтрокаРВ);
	Для Сч = 1 По Длина - 1 Цикл
		Символ	= Сред(СтрокаРВ,Сч,1);
		Символ1	= Сред(СтрокаРВ,Сч+1,1);
		Если Найти(Гласные, Символ) = 0 И Найти(Гласные, Символ1) > 0 Тогда
			Р1	= Сч + 1;
			Прервать;
		КонецЕсли;
	КонецЦикла;
	Если Р1 = 0 Тогда
		Возврат;
	КонецЕсли;
	//Определение Р2
	СтрокаР1= Сред(СтрокаРВ, Р1);
	Длина	= СтрДлина(СтрокаР1);
	Для Сч = 1 По Длина - 1 Цикл
		Символ	= Сред(СтрокаР1,Сч,1);
		Символ1	= Сред(СтрокаР1,Сч+1,1);
		Если Найти(Гласные, Символ) = 0 И Найти(Гласные, Символ1) > 0 Тогда
			Р2	= Р1 + Сч;
			Прервать;
		КонецЕсли;
	КонецЦикла;
	Возврат;
	
	
КонецПроцедуры

Функция ОтобратьДоГерундия(Строка)

	Длина	= СтрДлина(Строка);
	Если Длина >= 6 Тогда
		С6	= Прав(Строка,6);
		Если Найти("ившись|ывшись", С6) > 0 Тогда
			Строка	= Лев(Строка, СтрДлина(Строка)-6);
			Возврат Истина;
		ИначеЕсли Найти("авшись|явшись", С6) > 0 Тогда
			Строка	= Лев(Строка, СтрДлина(Строка)-5);
			Возврат Истина;
		КонецЕсли;
	КонецЕсли; 
	Если Длина >= 4 Тогда
		С4	= Прав(Строка,4);
		Если Найти("ивши|ывши", С4) > 0 Тогда
			Строка	= Лев(Строка, СтрДлина(Строка)-4);
			Возврат Истина;
		ИначеЕсли Найти("авши|явши", С4) > 0 Тогда
			Строка	= Лев(Строка, СтрДлина(Строка)-3);
			Возврат Истина;
		КонецЕсли;
	КонецЕсли; 
	Если Длина >= 2 Тогда
		С2	= Прав(Строка,2);
		Если Найти("ив|ыв", С2) > 0 Тогда
			Строка	= Лев(Строка, СтрДлина(Строка)-2);
			Возврат Истина;
		ИначеЕсли Найти("ав|яв", С2) > 0 Тогда
			Строка	= Лев(Строка, СтрДлина(Строка)-1);
			Возврат Истина;
		КонецЕсли;
	КонецЕсли; 
	
	Возврат Ложь;

КонецФункции

Функция ОтобратьОтражательныеОкончания(Строка)

	Длина	= СтрДлина(Строка);
	Если Длина >= 2 Тогда
		С2	= Прав(Строка,2);
		Если Найти("ся|сь", С2) > 0 Тогда
			Строка	= Лев(Строка, СтрДлина(Строка)-2);
			Возврат Истина;
		КонецЕсли; 
	КонецЕсли;

	Возврат Ложь;

КонецФункции

Функция ОтобратьПрилагательное(Строка)

	Длина	= СтрДлина(Строка);
	Найдено	= Ложь;
	Если Длина >= 3 Тогда
		С3	= Прав(Строка,3);
		Если Найти("ими|ыми|его|ого|ему|ому", С3) > 0 Тогда
			Строка	= Лев(Строка, СтрДлина(Строка)-3);
			Длина	= Длина - 3;
			Найдено	= Истина;
		КонецЕсли;
	КонецЕсли;
	Если (НЕ Найдено) И (Длина >= 2) Тогда
		С2	= Прав(Строка,2);
		Если Найти("ее|ие|ые|ое|ей|ий|ый|ой|ем|им|ым|ом|их|ых|ую|юю|ая|яя|ою|ею", С2) > 0 Тогда
			Строка	= Лев(Строка, СтрДлина(Строка)-2);
			Длина	= Длина - 2;
			Найдено	= Истина;
		КонецЕсли;
	КонецЕсли;
	Если Найдено Тогда
		Если Длина >= 3 Тогда
			С3	= Прав(Строка,3);
			Если Найти("ивш|ывш|ующ", С3) > 0 Тогда
				Строка	= Лев(Строка, СтрДлина(Строка)-3);
				Возврат	Истина;
			ИначеЕсли Найти("аем|анн|авш|ающ|яем|янн|явш|яющ", С3) > 0 Тогда
				Строка	= Лев(Строка, СтрДлина(Строка)-2);
				Возврат	Истина;
			КонецЕсли;
		КонецЕсли; 
		Если Длина >= 2 Тогда
			С2	= Прав(Строка,2);
			Если Найти("ащ|ящ", С2) > 0 Тогда
				Строка	= Лев(Строка, СтрДлина(Строка)-1);
				Возврат	Истина;
			КонецЕсли;
		КонецЕсли;
		Возврат Истина;
	КонецЕсли; 

	Возврат Ложь;

КонецФункции

Функция ОтобратьГлагол(Строка)

	Длина	= СтрДлина(Строка);
	Если Длина >= 4 Тогда
		С4	= Прав(Строка,4);
		Если Найти("ейте|уйте", С4) > 0 Тогда
			Строка	= Лев(Строка, СтрДлина(Строка)-4);
			Возврат Истина;
		ИначеЕсли Найти("аете|айте|аешь|анно|яете|яйте|яешь|янно", С4) > 0 Тогда
			Строка	= Лев(Строка, СтрДлина(Строка)-3);
			Возврат Истина;
		КонецЕсли;
	КонецЕсли; 
	Если Длина >= 3 Тогда
		С3	= Прав(Строка,3);
		Если Найти("ила|ыла|ена|ите|или|ыли|ило|ыло|ено|ует|уют|ены", С3) > 0 Тогда
			Строка	= Лев(Строка, СтрДлина(Строка)-3);
			Возврат Истина;
		ИначеЕсли Найти("ала|ана|али|аем|ало|ано|ает|ают|аны|ать|аешь|яла|яна|яли|яем|яло|яно|яет|яют|яны|ять|яешь", С3) > 0 Тогда
			Строка	= Лев(Строка, СтрДлина(Строка)-2);
			Возврат Истина;
		КонецЕсли;
	КонецЕсли; 
	Если Длина >= 2 Тогда
		С2	= Прав(Строка,2);
		Если Найти("ей|уй|ил|ыл|им|ым|ен|ят|ит|ыт|ую", С2) > 0 Тогда
			Строка	= Лев(Строка, СтрДлина(Строка)-2);
			Возврат Истина;
		ИначеЕсли Найти("ай|ал|ан|яй|ял|ян", С2) > 0 Тогда
			Строка	= Лев(Строка, СтрДлина(Строка)-1);
			Возврат Истина;
		КонецЕсли;
	КонецЕсли; 
	Если Длина >= 1 Тогда
		С1	= Прав(Строка,1);
		Если С1	= "ю" Тогда
			Строка	= Лев(Строка, СтрДлина(Строка)-1);
			Возврат Истина;
		КонецЕсли;
	КонецЕсли;

	Возврат Ложь;

КонецФункции

Функция ОтобратьСуществительное(Строка)

	Длина	= СтрДлина(Строка);
	Если Длина >= 4 Тогда
		С4	= Прав(Строка,4);
		Если Найти("иями", С4) > 0 Тогда
			Строка	= Лев(Строка, СтрДлина(Строка)-4);
			Возврат Истина;
		КонецЕсли;
	КонецЕсли; 
	Если Длина >= 3 Тогда
		С3	= Прав(Строка,3);
		Если Найти("ями|ами|ией|иям|ием|иях", С3) > 0 Тогда
			Строка	= Лев(Строка, СтрДлина(Строка)-3);
			Возврат Истина;
		КонецЕсли;
	КонецЕсли; 
	Если Длина >= 2 Тогда
		С2	= Прав(Строка,2);
		Если Найти("ев|ов|ие|ье|еи|ии|ей|ой|ий|ям|ем|ам|ом|ах|ях|ию|ью|ия|ья", С2) > 0 Тогда
			Строка	= Лев(Строка, СтрДлина(Строка)-2);
			Возврат Истина;
		КонецЕсли;
	КонецЕсли; 
	Если Длина >= 1 Тогда
		С1	= Прав(Строка,1);
		Если Найти("а|е|и|й|о|у|ы|ь|ю|я", С1) > 0 Тогда
			Строка	= Лев(Строка, СтрДлина(Строка)-1);
			Возврат Истина;
		КонецЕсли;
	КонецЕсли;

	Возврат Ложь;

КонецФункции

Функция ОтобратьСловооразовательноеОкончание(Строка, Р2)

	Если Лев(Р2, 4) = "ость" Тогда
		Строка	= Лев(Строка, СтрДлина(Строка)-4);
		Возврат Истина;
	ИначеЕсли Лев(Р2, 3) = "ост" Тогда
		Строка	= Лев(Строка, СтрДлина(Строка)-3);
		Возврат Истина;
	КонецЕсли;

	Возврат Ложь;

КонецФункции

Функция УбратьЧислаЗнакиПрипинанияИОператорыИзСтроки(Строка)
	
	Результат = "";
	УдаляемыеСимволы = "!""№;%:?*()_-+=.,\/{}|[]1234567890	" + Символы.НПП + Символы.ВК + Символы.ПС + Символы.ПФ + Символы.ВТаб;
	
	ДлинаСтроки = СтрДлина(Строка);
	
	Для Индекс = 1 По ДлинаСтроки Цикл
		Символ = Сред(Строка, Индекс, 1);
		Если СтрНайти(УдаляемыеСимволы, Символ) = 0 Тогда
			Результат = Результат + Символ;
		КонецЕсли; 
	КонецЦикла; 
	
	Возврат Результат
	
КонецФункции
 
Функция ПолучитьСтем(Слово) Экспорт
	
	Стем	= Слово;
	Стем	= НРег(Стем);
	Стем	= СтрЗаменить(Стем, "ё", "е");

	ПозицияРВ	= 0;//Позиция относительно начала слова
	ПозицияР1	= 0;//позиция относительно начала РВ
	ПозицияР2	= 0;//позиция относительно начала РВ

	ПолучитьПозиции(Стем, ПозицияРВ, ПозицияР1, ПозицияР2);
	
	Если ПозицияРВ = 0 Тогда
		Возврат Стем;
	КонецЕсли; 
	РВ		= Сред(Стем,ПозицияРВ);
	Старт	= Лев(Стем, ПозицияРВ-1);
	Если НЕ ЗначениеЗаполнено(РВ) Тогда
		Возврат Стем;
	КонецЕсли;
	
	//Шаг 1
	Если НЕ ОтобратьДоГерундия(РВ) Тогда
		ОтобратьОтражательныеОкончания(РВ);
		Если ОтобратьПрилагательное(РВ) Тогда
		ИначеЕсли ОтобратьГлагол(РВ) Тогда
		Иначе
			ОтобратьСуществительное(РВ);
		КонецЕсли;
		
	КонецЕсли; 
	//Шаг 2
	Если Прав(РВ,1) = "и" Тогда
		РВ	= Лев(РВ, СтрДлина(РВ)-1);
	КонецЕсли; 
	//Шаг 3
	Если ПозицияР2 > 0 И СтрДлина(РВ) > ПозицияР2 Тогда
		СтрокаР2	= Сред(РВ, ПозицияР2);
		ОтобратьСловооразовательноеОкончание(РВ, СтрокаР2);
	КонецЕсли; 
	//Шаг 4
	Если Прав(РВ,1) = "ь" Тогда
		РВ	= Лев(РВ, СтрДлина(РВ)-1);
	Иначе
		Если Прав(РВ,4) = "ейше" Тогда
			РВ	= Лев(РВ, СтрДлина(РВ)-4);
		ИначеЕсли Прав(РВ,3) = "ейш" Тогда
			РВ	= Лев(РВ, СтрДлина(РВ)-3);
		КонецЕсли;
		Если Прав(РВ,2) = "нн" Тогда
			РВ	= Лев(РВ, СтрДлина(РВ)-1);
		КонецЕсли;
	КонецЕсли;

	Возврат Старт + РВ;
	
КонецФункции // Стемминг()
 
Функция Metaphone(Знач W) Экспорт
	
    //alf - алфавит кроме исключаемых букв, cns1 и cns2 - звонкие и глухие
    //согласные, cns3 - согласные, перед которыми звонкие оглушаются,
    //  ch, ct - образец и замена гласных
    alf = "ОЕАИУЭЮЯПСТРКЛМНБВГДЖЗЙФХЦЧШЩЁЫ";
    cns1 = "БЗДВГ";
    cns2 = "ПСТФК";
    cns3 = "ПСТКБВГДЖЗФХЦЧШЩ";
    ch = "ОЮЕЭЯЁЫ";
    ct = "АУИИАИА";
    //S, V - промежуточные строки, i - счётчик цикла, B - позиция
    //найденного элемента, c$ - текущий символ, c_old$ - предыдущий символ
    S= "";
    V= "";
    i= 0;
    B= 0;
    c= "";
    old_c = "";

    //Переводим в верхний регистр, оставляем только
    //символы из alf и копируем в S:
    W = Врег(W);
    Для i = 1 По СтрДлина(W) Цикл
        c = Сред(W, i, 1);
        Если Найти(alf, c) > 0 Тогда
            S = S + c;
        КонецЕсли;
    КонецЦикла;
    Если СтрДлина(S) = 0 Тогда
        Возврат "";
    КонецЕсли;

    //Сжимаем окончания:
    Врем = Прав(S, 6);
    Если Врем = "ОВСКИЙ"  Тогда
        S = Лев(S, СтрДлина(S) - 6) + "@";
    ИначеЕсли Врем = "ЕВСКИЙ" Тогда
        S = Лев(S, СтрДлина(S) - 6) + "#";
    ИначеЕсли Врем = "ОВСКАЯ" Тогда
        S = Лев(S, СтрДлина(S) - 6) + "$";
    ИначеЕсли Врем = "ЕВСКАЯ" Тогда
        S = Лев(S, СтрДлина(S) - 6) + "%";
    Иначе
        Врем = Прав(S, 4);
        Если (Врем = "ИЕВА") ИЛИ (Врем = "ЕЕВА") Тогда
            S = Лев(S, СтрДлина(S) - 4) + "9";
        ИначеЕсли (Врем = "ОВНА") ИЛИ (Врем = "ЕВНА") Тогда
            S = Лев(S, СтрДлина(S) - 4) + "8";
        ИначеЕсли (Врем = "ОВИЧ") ИЛИ (Врем = "ЕВИЧ") Тогда
            S = Лев(S, СтрДлина(S) - 4) + "7";
        Иначе
            Врем = Прав(S, 3);
            Если (Врем = "ОВА") ИЛИ (Врем = "ЕВА") Тогда
                S = Лев(S, СтрДлина(S) - 3) + "9";
            ИначеЕсли Врем = "ИНА" Тогда
                S = Лев(S, СтрДлина(S) - 3) + "1";
            ИначеЕсли (Врем = "ИЕВ") ИЛИ (Врем = "ЕЕВ") Тогда
                S = Лев(S, СтрДлина(S) - 3) + "4";
            ИначеЕсли Врем = "НКО" Тогда
                S = Лев(S, СтрДлина(S) - 3) + "3";
            Иначе
                Врем = Прав(S, 2);
                Если (Врем = "ОВ") ИЛИ (Врем = "ЕВ") Тогда
                    S = Лев(S, СтрДлина(S) - 2) + "4";
                ИначеЕсли Врем = "АЯ" Тогда
                    S = Лев(S, СтрДлина(S) - 2) + "6";
                ИначеЕсли (Врем = "ИЙ") ИЛИ (Врем = "ЫЙ") Тогда
                    S = Лев(S, СтрДлина(S) - 2) + "7";
                ИначеЕсли (Врем = "ЫХ") ИЛИ (Врем = "ИХ") Тогда
                    S = Лев(S, СтрДлина(S) - 2) + "5";
                ИначеЕсли (Врем = "ИН") Тогда
                    S = Лев(S, СтрДлина(S) - 2) + "8";
                ИначеЕсли (Врем = "ИК") ИЛИ (Врем = "ЕК") Тогда
                    S = Лев(S, СтрДлина(S) - 2) + "2";
                ИначеЕсли (Врем = "УК") ИЛИ (Врем = "ЮК") Тогда
                    S = Лев(S, СтрДлина(S) - 2) + "0";
                КонецЕсли;
            КонецЕсли;
        КонецЕсли;
    КонецЕсли;

    //Оглушаем последний символ, если он - звонкий согласный:
    B = Найти(cns1, Прав(S, 1));
    Если B > 0 Тогда
        S = Сред(S, СтрДлина(S)-1, 1);
        S = S + Сред(cns2, B, 1);
    КонецЕсли;
    old_c = " ";
    //Основной цикл:
    Для i = 1 По СтрДлина(S) Цикл
        c = Сред(S, i, 1);
        B = Найти(ch, c);
        Если B > 0 Тогда //Если гласная
            Если (old_c = "Й") ИЛИ (old_c = "И") Тогда
                Если (c = "О") ИЛИ (c = "Е") Тогда //Буквосочетания с гласной
                    old_c = "И";
                    V = Сред(V, СтрДлина(V)-1, 1);
                    V = V + old_c;
                Иначе //Если не буквосочетания с гласной, а просто гласная
                    Если c <> old_c Тогда
                        V = V + Сред(ct, B, 1);
                    КонецЕсли;
                КонецЕсли;
            Иначе //Если не буквосочетания с гласной, а просто гласная
                Если c <> old_c Тогда
                        V = V + Сред(ct, B, 1);
                КонецЕсли;
            КонецЕсли;
        Иначе //Если согласная
            Если c <> old_c Тогда //для «Аввакумов»
                Если Найти(cns3, c) > 0 Тогда //Оглушение согласных
                    B = Найти(cns1, old_c);
                КонецЕсли;
                Если B > 0 Тогда
                    old_c = Сред(cns2, B, 1);
                    V = Сред(V, СтрДлина(V)-1, 1);
                    V = V + old_c;
                КонецЕсли;
                Если c <> old_c Тогда
                    V = V + c; //для «Шмидт»
                КонецЕсли;
            КонецЕсли;
        КонецЕсли;
        old_c = c;
    КонецЦикла;
    Возврат V;
	
КонецФункции

#КонецОбласти

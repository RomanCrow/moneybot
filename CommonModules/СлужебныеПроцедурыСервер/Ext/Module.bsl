﻿Процедура ЗагрузитьПроксиИзФайла(Тип = Неопределено) Экспорт
	
	ПроверитьОстаткиПроксиИУведомитьАдминистратора();
	
	АдресФайла = Константы.АдресФайлаСПрокси.Получить();
	Если ПустаяСтрока(АдресФайла) Тогда
		Возврат;
	КонецЕсли;
	
	ТекДок = Новый ТекстовыйДокумент;
	ТекДок.Прочитать(АдресФайла);
	КолвоСтрок = ТекДок.КоличествоСтрок();
	
	ТЗ = Новый ТаблицаЗначений;
	ТЗ.Колонки.Добавить("Сервер",Новый ОписаниеТипов("Строка",,Новый КвалификаторыСтроки(50)));
	ТЗ.Колонки.Добавить("Порт",Новый ОписаниеТипов("Строка",,Новый КвалификаторыСтроки(10)));
	
	Для НомерСтроки = 1 По КолвоСтрок Цикл
		
		Строка = ТекДок.ПолучитьСтроку(НомерСтроки);
		
		Массив = СтрРазделить(Строка, ":");
		
		Если Массив.Количество() < 2 Тогда
			Продолжить;
		КонецЕсли; 
		
		НовСтрока = ТЗ.Добавить();
		НовСтрока.Сервер = Массив[0];
		НовСтрока.Порт = Массив[1]; 
		
	КонецЦикла; 
	
	ТекДок.Очистить();
	ТекДок.Записать(АдресФайла);
	
	Запрос = Новый Запрос;
	Запрос.Текст = 
	"ВЫБРАТЬ
	|	ТЗ.Сервер КАК Сервер,
	|	ТЗ.Порт КАК Порт
	|ПОМЕСТИТЬ ВТ_ТЗ
	|ИЗ
	|	&ТЗ КАК ТЗ
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|ВЫБРАТЬ
	|	ВТ_ТЗ.Сервер КАК Сервер,
	|	ВТ_ТЗ.Порт КАК Порт
	|ИЗ
	|	ВТ_ТЗ КАК ВТ_ТЗ
	|		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.Прокси КАК Прокси
	|		ПО ВТ_ТЗ.Сервер = Прокси.Сервер
	|			И ВТ_ТЗ.Порт = Прокси.Порт
	|ГДЕ
	|	Прокси.Сервер ЕСТЬ NULL";
	Запрос.УстановитьПараметр("ТЗ", ТЗ);
	РезультатЗапроса = Запрос.Выполнить();
	
	Если РезультатЗапроса.Пустой() Тогда
		Сообщить("Все данные из файла уже загружены");
	Иначе
		Выборка = РезультатЗапроса.Выбрать();
		Пока Выборка.Следующий() Цикл
			НовСпр = Справочники.Прокси.СоздатьЭлемент();
			НовСпр.Наименование = Выборка.Сервер;
			НовСпр.Сервер = Выборка.Сервер;
			НовСпр.Порт = Выборка.Порт;
			НовСпр.ТипПрокси = ?(ЗначениеЗаполнено(Тип), Тип, Перечисления.ТипыПрокси.socks5);
			НовСпр.Записать();
		КонецЦикла;
		Сообщить("Успешная загрузка");
	КонецЕсли; 
	 
	
КонецПроцедуры

Процедура ПроверитьОстаткиПроксиИУведомитьАдминистратора()
	
	Запрос = Новый Запрос;
	Запрос.Текст = 
	"ВЫБРАТЬ
	|	КОЛИЧЕСТВО(РАЗЛИЧНЫЕ Прокси.Ссылка) КАК Количество
	|ИЗ
	|	Справочник.Прокси КАК Прокси";
	Выборка = Запрос.Выполнить().Выбрать();
	Выборка.Следующий();
	
	Если Выборка.Количество <= Константы.МинимальныйОстатокПрокси.Получить() Тогда
		
		МассивПользователей = ПользователиИнформационнойБазы.ПолучитьПользователей();
		
		Для Каждого Пользователь Из МассивПользователей Цикл
			ЕстьРольАдминистратора = Ложь;
			Для Каждого Роль Из Пользователь.Роли Цикл
				Если Роль.Имя = "Администратор" Тогда
					ЕстьРольАдминистратора = Истина;
					Прервать;
				КонецЕсли; 
			КонецЦикла; 
			
			Если ЕстьРольАдминистратора Тогда
				
				УИД = Пользователь.УникальныйИдентификатор;
				
				СпрПользователь = Справочники.Пользователи.НайтиПоРеквизиту("ИдентификаторПользователяИБ",УИД);
				
				Если Не СпрПользователь.Пустая() И ЗначениеЗаполнено(СпрПользователь.ИДЧата) Тогда
					
					ИДБота = Константы.ИДБота.Получить();
					Соединение = ОбменТелеграмСервер.ПодключениеИПроверкаТелеграм(ИДБота);
					Если Соединение = Неопределено Тогда
						Возврат;
					КонецЕсли;
					
					Сообщение = "В базе бюджета заканчиваются прокси. Осталось " + Выборка.Количество + " элементов. Заполните список прокси новыми данными.";
					
					ОбменТелеграмСервер.ОтправитьСообщение(Соединение, ИДБота, СпрПользователь.ИДЧата, Сообщение);
					
				КонецЕсли; 
				
			КонецЕсли;
			
		КонецЦикла; 
		
	КонецЕсли;
	
КонецПроцедуры

Процедура ПриНачалеРаботыСистемы() Экспорт
	
	ТекПользователь = ПользователиИнформационнойБазы.ТекущийПользователь();
	
	Пользователь = Справочники.Пользователи.НайтиПоРеквизиту("ИдентификаторПользователяИБ", ТекПользователь.УникальныйИдентификатор);
	Если Пользователь.Пустая() Тогда
		Пользователь = Справочники.Пользователи.НайтиПоНаименованию(ТекПользователь.Имя);
		Если Пользователь.Пустая() Тогда
			Пользователь = Справочники.Пользователи.СоздатьИЗаполнитьДанными(ТекПользователь.Имя, ТекПользователь.УникальныйИдентификатор);
			Сообщить("Был создан новый пользователь");
		Иначе
			Спр = Пользователь.ПолучитьОбъект();
			Спр.ИдентификаторПользователяИБ = ТекПользователь.УникальныйИдентификатор;
			Спр.Записать();
		КонецЕсли; 
	КонецЕсли;
	
	ПараметрыСеанса.ТекущийПользователь = Пользователь;
	
КонецПроцедуры

Процедура ОбновитьIAMЯндекс() Экспорт
	
	СоединениеЯндекс = Новый HTTPСоединение("iam.api.cloud.yandex.net", 443, , , , 20, Новый ЗащищенноеСоединениеOpenSSL(), Неопределено);
	
	Заголовки = Новый Соответствие;
	Заголовки.Вставить("Content-Type","application/json");
	Запрос = Новый HTTPЗапрос("/iam/v1/tokens",Заголовки);
	СтрокаТела = "{""yandexPassportOauthToken"": """ + Константы.OAUTHТокен.Получить() + """}";
	Запрос.УстановитьТелоИзСтроки(СтрокаТела,КодировкаТекста.UTF8);
	
	ФайлИтога = ПолучитьИмяВременногоФайла();
	СоединениеЯндекс.ОтправитьДляОбработки(Запрос, ФайлИтога);
	
	ТекДок = Новый ТекстовыйДокумент;
	ТекДок.Прочитать(ФайлИтога);
	
	Ответ = ТекДок.ПолучитьТекст();
	Чтение = Новый ЧтениеJSON;
	Чтение.УстановитьСтроку(Ответ);
	СтруктураОтвета = ПрочитатьJSON(Чтение);
	
	Константы.IAMТокенЯндекс.Установить(СтруктураОтвета.iamToken);
	
КонецПроцедуры

Функция СклоненияСтроки(Строка) Экспорт
	Соединение = Новый HTTPСоединение("ws3.morpher.ru",443,,,,,Новый ЗащищенноеСоединениеOpenSSL());
	Запрос = Новый HTTPЗапрос("/russian/declension?s=" + СтрЗаменить(Строка, " ", "%20") + "&format=json");
	Ответ = Соединение.Получить(Запрос);
	СтрокаОтвет = Ответ.ПолучитьТелоКакСтроку();
	Чтение = Новый ЧтениеJSON;
	Чтение.УстановитьСтроку(СтрокаОтвет);
	СтруктураОтвета = ПрочитатьJSON(Чтение);
	
	ТЗСтрок = Новый ТаблицаЗначений;
	ТЗСтрок.Колонки.Добавить("СклоненноеИмя",Новый ОписаниеТипов("Строка"));
	НовСтрока = ТЗСтрок.Добавить();
	НовСтрока.СклоненноеИмя = Строка;
	Для Каждого Ответ Из СтруктураОтвета Цикл
		Ключ = Ответ.Ключ;
		Если Ключ = "П" Или Ключ = "В" Или Ключ = "Р" Или Ключ = "Д" Или Ключ = "Т" Тогда
			НовСтрока = ТЗСтрок.Добавить();
			НовСтрока.СклоненноеИмя = Ответ.Значение;
		КонецЕсли; 
	КонецЦикла; 
	
	Возврат ТЗСтрок;
	
КонецФункции
  

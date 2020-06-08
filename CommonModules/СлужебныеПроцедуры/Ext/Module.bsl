﻿
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
					Соединение = ОбменТелеграм.ПодключениеИПроверкаТелеграм(ИДБота);
					Если Соединение = Неопределено Тогда
						Возврат;
					КонецЕсли;
					
					Сообщение = "В базе бюджета заканчиваются прокси. Осталось " + Выборка.Количество + " элементов. Заполните список прокси новыми данными.";
					
					ОбменТелеграм.ОтправитьСообщение(Соединение, ИДБота, СпрПользователь.ИДЧата, Сообщение);
					
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
	
	Параметры = Новый Структура;
	Соединение = Новый HTTPСоединение("iam.api.cloud.yandex.net", 443, , , , 20, Новый ЗащищенноеСоединениеOpenSSL(), Неопределено);
	Параметры.Вставить("Соединение", Соединение);
	
	ПараметрыЗапроса = ПолучитьПараметрыHTTPЗапроса();
	ПараметрыЗапроса.Заголовки.Вставить("Content-Type","application/json");
	ПараметрыЗапроса.ИмяМетода = "POST";
	ПараметрыЗапроса.ТекстЗапроса = "/iam/v1/tokens";
	ПараметрыЗапроса.ТелоЗапроса = "{""yandexPassportOauthToken"": """ + Константы.OAUTHТокенЯндекс.Получить() + """}";
	
	СтруктураОтвета = ВыполнитьHTTPЗапрос(Параметры, ПараметрыЗапроса).СтруктураОтвета;
	
	Константы.IAMТокенЯндекс.Установить(СтруктураОтвета.iamToken);
	
КонецПроцедуры

Функция СклоненияСтроки(Знач Строка, Падеж = "") Экспорт
	
	ПараметрыСоединения = Новый Структура;
	Соединение = Новый HTTPСоединение("ws3.morpher.ru",443,,,,,Новый ЗащищенноеСоединениеOpenSSL());
	ПараметрыСоединения.Вставить("Соединение", Соединение);
	
	ПараметрыЗапроса = ПолучитьПараметрыHTTPЗапроса();
	ПараметрыЗапроса.ТекстСообщения = "/russian/declension?s=" + СтрЗаменить(Строка, " ", "%20") + "&format=json";
	
	СтруктураОтвета = ВыполнитьHTTPЗапрос(ПараметрыСоединения, ПараметрыЗапроса).СтруктураОтвета;
	
	Результат = Новый ТаблицаЗначений;
	Результат.Колонки.Добавить("Падеж", Новый ОписаниеТипов("Строка"));
	Результат.Колонки.Добавить("Значение", Новый ОписаниеТипов("Строка"));
	
	НовСтрока = Результат.Добавить();
	НовСтрока.Падеж = "И";
	НовСтрока.Значение = Строка;
		
	Для Каждого Ответ Из СтруктураОтвета Цикл
		Если Не ЗначениеЗаполнено(Падеж) Или Падеж = Ответ.Ключ Тогда
			НовСтрока = Результат.Добавить();
			НовСтрока.Падеж = Ответ.Ключ;
			НовСтрока.Значение = Ответ.Значение;
		КонецЕсли; 	 
	КонецЦикла; 
	
	Возврат Результат;
	
КонецФункции
  
Процедура ОбновитьПрокси() Экспорт
	
	Соединение = Новый HTTPСоединение("www.proxy-list.download",443,,,,,Новый ЗащищенноеСоединениеOpenSSL());	
	Запрос = Новый HTTPЗапрос("/api/v1/get?type=socks5&anon=elite&country=US");
	Ответ = Соединение.Получить(Запрос,);
	Если Ответ.КодСостояния = 200 Тогда
		СтрокаОтвет = Ответ.ПолучитьТелоКакСтроку();
		МассивОтвета = СтрРазделить(СтрокаОтвет, Символы.ПС);
		Для Каждого Прокси Из МассивОтвета Цикл
			
			Данные = СтрРазделить(Прокси, ":");
			Если Не ЗначениеЗаполнено(Данные[0]) Тогда
				Продолжить;
			КонецЕсли; 
			
			Если Данные.Количество() = 1 Тогда
				Порт = 8080;
			Иначе
				Порт = Число(Данные[1]);
			КонецЕсли; 
			Сервер = Данные[0];
			
			НовСпр = Справочники.Прокси.СоздатьЭлемент();
			НовСпр.Наименование = Прокси;
			НовСпр.ТипПрокси = Перечисления.ТипыПрокси.socks5;
			НовСпр.Сервер = Сервер;
			НовСпр.Порт = Число(Порт);
			НовСпр.Записать();
			
		КонецЦикла; 
	КонецЕсли; 
		
КонецПроцедуры
 
Функция ПолучитьПараметрыHTTPЗапроса() Экспорт
	
	Результат = Новый Структура;
	Результат.Вставить("ИмяМетода", "GET");
	Результат.Вставить("ТекстЗапроса", "");
	Результат.Вставить("Заголовки", Новый Соответствие);
	Результат.Вставить("ТелоЗапроса", "");
	
	Возврат Результат;
	
КонецФункции

Функция ВыполнитьHTTPЗапрос(ПараметрыСоединения, ПараметрыЗапроса) Экспорт
	
	Соединение = ПараметрыСоединения.Соединение;
	
	Запрос = Новый HTTPЗапрос(ПараметрыЗапроса.ТекстЗапроса, ПараметрыЗапроса.Заголовки); 
	
	Если ТипЗнч(ПараметрыЗапроса.ТелоЗапроса) = Тип("ДвоичныеДанные") Тогда
		Запрос.УстановитьТелоИзДвоичныхДанных(ПараметрыЗапроса.ТелоЗапроса);
	Иначе
		Запрос.УстановитьТелоИзСтроки(ПараметрыЗапроса.ТелоЗапроса);
	КонецЕсли;
	
	Ответ = Соединение.ВызватьHTTPМетод(ПараметрыЗапроса.ИмяМетода, Запрос);
	СтрокаОтвет = Ответ.ПолучитьТелоКакСтроку();
	
	Чтение = Новый ЧтениеJSON;
	Чтение.УстановитьСтроку(СтрокаОтвет);
	Попытка
		СтруктураОтвета = ПрочитатьJSON(Чтение);
	Исключение
	    СтруктураОтвета = Неопределено;
	КонецПопытки; 
	
	Результат = Новый Структура;
	Результат.Вставить("Ответ", Ответ);
	Результат.Вставить("СтрокаОтвет", СтрокаОтвет);
	Результат.Вставить("ДвоичныеДанныеОтвет", Ответ.ПолучитьТелоКакДвоичныеДанные());
	Результат.Вставить("СтруктураОтвета", СтруктураОтвета);
	
	Возврат Результат;
	
КонецФункции

Процедура ОчиститьНерабочиеПрокси() Экспорт
	
	Запрос = Новый Запрос;
	Запрос.Текст = 
	"ВЫБРАТЬ
	|	Прокси.Ссылка КАК Ссылка
	|ИЗ
	|	Справочник.Прокси КАК Прокси
	|ГДЕ
	|	Прокси.ПометкаУдаления";
	РезультатЗапроса = Запрос.Выполнить();
	Если Не РезультатЗапроса.Пустой() Тогда
		Выборка = РезультатЗапроса.Выбрать();
		Пока Выборка.Следующий() Цикл
			Попытка
				Выборка.Ссылка.ПолучитьОбъект().Удалить();
			Исключение
			    // запись в жр
			КонецПопытки; 	
		КонецЦикла; 
	КонецЕсли; 
	 	
	
КонецПроцедуры
 
Функция ДатаАпи(Дата) Экспорт
	
	Запрос = Новый Запрос;
	Запрос.Текст = 
	"ВЫБРАТЬ
	|	ДОБАВИТЬКДАТЕ(&ПромежуточнаяДата, ЧАС, &ЧасовойПояс) КАК Дата";
	Запрос.УстановитьПараметр("ПромежуточнаяДата", '19700101' + Дата);
	Запрос.УстановитьПараметр("ЧасовойПояс", Константы.ЧасовойПояс.Получить());
	РезультатЗапроса = Запрос.Выполнить().Выбрать();
	РезультатЗапроса.Следующий();
	 
	Возврат РезультатЗапроса.Дата;
	
КонецФункции
 
Функция СписокПрокси(Параметры) Экспорт
	
	Результат = Новый ТаблицаЗначений;
	Результат.Колонки.Добавить("Ссылка");
	Результат.Колонки.Добавить("ТипПрокси");
	Результат.Колонки.Добавить("Сервер");
	Результат.Колонки.Добавить("Порт");
	Результат.Колонки.Добавить("Пользователь");
	Результат.Колонки.Добавить("Пароль");
	
	Если Параметры.ИспользоватьПрокси Тогда
		Запрос = Новый Запрос;
		Запрос.Текст = 
		"ВЫБРАТЬ
		|	Прокси.Ссылка КАК Ссылка,
		|	Прокси.ТипПрокси КАК ТипПрокси,
		|	Прокси.Сервер КАК Сервер,
		|	Прокси.Порт КАК Порт,
		|	Прокси.Пользователь КАК Пользователь,
		|	Прокси.Пароль КАК Пароль
		|ИЗ
		|	Справочник.Прокси КАК Прокси
		|ГДЕ
		|	НЕ Прокси.ПометкаУдаления";
		РезультатЗапроса = Запрос.Выполнить();	
		Если Не РезультатЗапроса.Пустой() Тогда	
			Выборка = РезультатЗапроса.Выбрать();
			Пока Выборка.Следующий() Цикл
				НоваяСтрока = Результат.Добавить();
				НоваяСтрока.Ссылка = Выборка.Ссылка;
				НоваяСтрока.ТипПрокси = Нрег(Выборка.ТипПрокси);
				НоваяСтрока.Сервер = Выборка.Сервер;
				НоваяСтрока.Порт = Выборка.Порт;
				НоваяСтрока.Пользователь = Выборка.Пользователь;
				НоваяСтрока.Пароль = Выборка.Пароль;
			КонецЦикла;
		КонецЕсли;
	КонецЕсли; 
	
	Результат.Добавить();
	
	Возврат Результат;
	
КонецФункции

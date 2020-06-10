﻿
#Область ПрограммныйИнтерфейс
 
Функция РаспознатьРечьYandexSpeeckKit(ДвоичныеДанные) Экспорт
	
	ОбновитьIAMЯндекс();	 
			
	ПараметрыСоединенияЯндекс = Новый Структура;
	СоединениеЯндекс = Новый HTTPСоединение("stt.api.cloud.yandex.net", 443, , , , 20, Новый ЗащищенноеСоединениеOpenSSL(), Неопределено);
	ПараметрыСоединенияЯндекс.Вставить("Соединение", СоединениеЯндекс);
	
	ПараметрыЗапроса = СлужебныеПроцедуры.ПолучитьПараметрыHTTPЗапроса();
	ПараметрыЗапроса.Заголовки.Вставить("Authorization", "Bearer " + Константы.IAMТокенЯндекс.Получить());
	ПараметрыЗапроса.Заголовки.Вставить("Content-Type", "application/json");
	ПараметрыЗапроса.ИмяМетода = "POST";
	ПараметрыЗапроса.ТекстЗапроса = "/speech/v1/stt:recognize/?topic=general&folderId=" + Константы.ИДКаталогаЯндекс.Получить() + "&lang=ru-RU";
	ПараметрыЗапроса.ТелоЗапроса = ДвоичныеДанные;
	
	СтруктураОтвета = СлужебныеПроцедуры.ВыполнитьHTTPЗапрос(ПараметрыСоединенияЯндекс, ПараметрыЗапроса).СтруктураОтвета;
	
	Возврат СтруктураОтвета.result;
	
КонецФункции

Процедура ОбновитьIAMЯндекс() Экспорт
	
	Параметры = Новый Структура;
	Соединение = Новый HTTPСоединение("iam.api.cloud.yandex.net", 443, , , , 20, Новый ЗащищенноеСоединениеOpenSSL(), Неопределено);
	Параметры.Вставить("Соединение", Соединение);
	
	ПараметрыЗапроса = СлужебныеПроцедуры.ПолучитьПараметрыHTTPЗапроса();
	ПараметрыЗапроса.Заголовки.Вставить("Content-Type","application/json");
	ПараметрыЗапроса.ИмяМетода = "POST";
	ПараметрыЗапроса.ТекстЗапроса = "/iam/v1/tokens";
	ПараметрыЗапроса.ТелоЗапроса = "{""yandexPassportOauthToken"": """ + Константы.OAUTHТокенЯндекс.Получить() + """}";
	
	СтруктураОтвета = СлужебныеПроцедуры.ВыполнитьHTTPЗапрос(Параметры, ПараметрыЗапроса).СтруктураОтвета;
	
	Константы.IAMТокенЯндекс.Установить(СтруктураОтвета.iamToken);
	
КонецПроцедуры

Функция ИспользоватьРаспознаваниеРечи() Экспорт
	
	Запрос = Новый Запрос;
	Запрос.Текст = 
	"ВЫБРАТЬ
	|	OAUTHТокенЯндекс.Значение КАК OAUTHТокен,
	|	ИДКаталогаЯндекс.Значение КАК ИДКаталога,
	|	ИспользоватьРаспознаваниеРечи.Значение КАК ИспользоватьРаспознаваниеРечи
	|ИЗ
	|	Константа.OAUTHТокенЯндекс КАК OAUTHТокенЯндекс,
	|	Константа.ИДКаталогаЯндекс КАК ИДКаталогаЯндекс,
	|	Константа.ИспользоватьРаспознаваниеРечи КАК ИспользоватьРаспознаваниеРечи";
	РезультатЗапроса = Запрос.Выполнить();
	Если РезультатЗапроса.Пустой() Тогда
		Возврат Ложь;
	Иначе
		Выборка = РезультатЗапроса.Выбрать();
		Выборка.Следующий();
		Если Выборка.ИспользоватьРаспознаваниеРечи
			 И ЗначениеЗаполнено(Выборка.OAUTHТокен) 
			 И ЗначениеЗаполнено(Выборка.ИДКаталога) Тогда
			Возврат Истина;
		Иначе
			Возврат Ложь;
		КонецЕсли; 
	КонецЕсли; 
	 
КонецФункции
 
#КонецОбласти
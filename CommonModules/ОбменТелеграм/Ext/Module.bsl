﻿#Область ПрограммныйИнтерфейс

Процедура ОтправитьОтчетЗаПериод(Начало, Конец) Экспорт
	
	BotID = Константы.ИДБота.Получить();
	
	Соединение = ПодключениеИПроверкаТелеграм(BotID);
	Если Соединение = Неопределено Тогда
		Возврат;
	КонецЕсли;
	
	ТекДата = ТекущаяДатаСеанса();
	ТекстСообщения = ОбработкаКоманд.ПолучитьТекстДетальногоАнализаЗаПериод(Начало, Конец);

	Пользователи = Справочники.Пользователи.Выбрать();
	
	Пока Пользователи.Следующий() Цикл
		
		ОтправитьСообщение(Соединение, BotID, Пользователи.ИДЧата, ТекстСообщения);
		
	КонецЦикла;
	
КонецПроцедуры 

Процедура ОбработатьКоманды() Экспорт
	
	Параметры = ПолучитьСтрктуруПараметровПоключения();
	
	Если Не ПодключениеИПроверкаТелеграм(Параметры) Тогда
		Возврат;
	КонецЕсли;
	
	ПолученныеСообщения = ПолучитьПоследниеСообщения(Параметры);
		
	Для Каждого Сообщение Из ПолученныеСообщения Цикл
		
		Запись = РегистрыСведений.СинхронизированныеДанные.СоздатьМенеджерЗаписи();
		Запись.ИДОбновления = СлужебныеПроцедурыКлиентСервер.СтрокаИзЧисла(Сообщение.update_id);
		Запись.Записать();
		
		СтруктураСообщения = Сообщение.message;
		Отправитель = Пользователи.НайтиПользователяПоИмени(СтруктураСообщения.from.username);
		Если Отправитель = Неопределено Тогда
			Продолжить;
		КонецЕсли;
		
		ДатаСообщения = СлужебныеПроцедуры.ДатаАпи(СтруктураСообщения.date);
		ТекстОтвета = "";
		
		Параметры.Вставить("ИДЧата", СлужебныеПроцедурыКлиентСервер.СтрокаИзЧисла(СтруктураСообщения.chat.id));
		
		Если ПустаяСтрока(Отправитель.ИДЧата) Тогда
			Спр = Отправитель.ПолучитьОбъект();
			Спр.ИДЧата = Параметры.ИДЧата;
			Спр.Записать();
		КонецЕсли; 
		
		ИДСообщения = СлужебныеПроцедурыКлиентСервер.СтрокаИзЧисла(СтруктураСообщения.message_id);
		
		Если СтруктураСообщения.chat.type <> "private" Тогда
			ОтправитьСообщение(Параметры, "Извините, я отправляю сообщения только лично", ИДСообщения); 	
		КонецЕсли; 
						
		Если СтруктураСообщения.Свойство("text") Тогда
			
			ТекстСообщения = СтруктураСообщения.text;
			
		ИначеЕсли СтруктураСообщения.Свойство("voice") Тогда 
			
			Если ОбменЯндекс.ИспользоватьРаспознаваниеРечи() Тогда
				ДД = ПолучитьЗвуковойФайл(Параметры, СтруктураСообщения);			
				ТекстСообщения = ОбменЯндекс.РаспознатьРечьYandexSpeeckKit(ДД);		
				ТекстОтвета = "Ваше сообщение: " + ТекстСообщения + Символы.ПС;
			Иначе
				ТекстОтвета = "Извините, настройки распознавания речи не заполнены. Распознавание речи не доступно..;(";
				ОтправитьСообщение(Параметры, ТекстОтвета, ИДСообщения);
				Возврат;
			КонецЕсли; 
					
		ИначеЕсли СтруктураСообщения.Свойство("photo") Тогда	
			
			ТекстСообщения = ПолучитьРаскодированныйQRКод(СтруктураСообщения.photo, Параметры);
		
		Иначе
			
			ОтправитьСообщение(Параметры, "Неизвестный тип сообщения, извините...;(", ИДСообщения);
			Продолжить;
			
		КонецЕсли;
							
		ПараметрыВыполненияКоманды = Новый Структура;
		ПараметрыВыполненияКоманды.Вставить("Команда", ОбработатьКомандыСообщения(ТекстСообщения));
		ПараметрыВыполненияКоманды.Вставить("ТекстСообщения", ТекстСообщения);
		ПараметрыВыполненияКоманды.Вставить("ТекстОтвета", ТекстОтвета);
		ПараметрыВыполненияКоманды.Вставить("Отправитель", Отправитель);
		ПараметрыВыполненияКоманды.Вставить("СтруктураСообщения", СтруктураСообщения);
		ПараметрыВыполненияКоманды.Вставить("ДатаСообщения", ДатаСообщения);
		
		ОбработкаКоманд.ОбработкаКоманды(ПараметрыВыполненияКоманды);
				
		ОтправитьСообщение(Параметры, ПараметрыВыполненияКоманды.ТекстОтвета, ИДСообщения);
		
			
	КонецЦикла; 
		
КонецПроцедуры

Функция ПодключениеИПроверкаТелеграм(Параметры) Экспорт
	
	Успешно = Ложь;
	
	Прокси = СлужебныеПроцедуры.СписокПрокси(Параметры);
	КоличествоСтрок = Прокси.Количество();
	Индекс = 0;
	
	Пока Не Успешно Цикл
		
		СтрокаПрокси = Прокси.Получить(Индекс);
		
		ИнтернетПрокси = ПолучитьИнтернетПроксиПоПараметрам(СтрокаПрокси);
		
		Соединение = Новый HTTPСоединение("api.telegram.org", 443, , , ИнтернетПрокси, 30, Новый ЗащищенноеСоединениеOpenSSL());
		Попытка		
			Запрос = Новый HTTPЗапрос(Параметры.ИДБота + "/getMe");	
			HTTPОтвет = Соединение.Получить(Запрос);
			Если HTTPОтвет.КодСостояния  = 200 Тогда				
				Успешно = Истина;					
			КонецЕсли;
		Исключение
			Если ЗначениеЗаполнено(СтрокаПрокси.Ссылка) Тогда
				ПроксиОбъект = СтрокаПрокси.Ссылка.ПолучитьОбъект();
				ПроксиОбъект.ПометкаУдаления = Истина;
				ПроксиОбъект.Записать();
			КонецЕсли; 			
		КонецПопытки;
		
		Если Индекс + 1 = КоличествоСтрок Тогда
			Прервать;
		Иначе
			Индекс = Индекс + 1;
		КонецЕсли; 
		
	КонецЦикла;   
	
	Если Успешно Тогда
		Параметры.Вставить("Соединение", Соединение);
	КонецЕсли; 
	
	СлужебныеПроцедуры.ОчиститьНерабочиеПрокси();
	
	Возврат Успешно;
	
КонецФункции
 
Функция ОтправитьСообщение(Параметры, ТекстСообщения, ОтветНаСообщениеИД = "", Голосом = Ложь) Экспорт
	
	ПараметрыЗапроса = СлужебныеПроцедуры.ПолучитьПараметрыHTTPЗапроса();
	ПараметрыЗапроса.ТекстЗапроса = Параметры.ИДБота + "/sendMessage?chat_id=" + Параметры.ИДЧата + "&text=" + ТекстСообщения
								 + ?(ПустаяСтрока(ОтветНаСообщениеИД),"","&reply_to_message_id=" + ОтветНаСообщениеИД);
	
	Если Голосом Тогда
		
		//Голосовухи
		
	Иначе	
		СлужебныеПроцедуры.ВыполнитьHTTPЗапрос(Параметры, ПараметрыЗапроса);
	КонецЕсли; 
	
	
КонецФункции

#КонецОбласти

#Область СлужебныеПроцедурыИФункции

Функция ПолучитьСтрктуруПараметровПоключения()
	
	Результат = Новый Структура;
	Результат.Вставить("ИДБота", "bot" + Константы.ИДБота.Получить());
	Результат.Вставить("ИспользоватьПрокси", Константы.ИспользоватьПрокси.Получить());
	
	Возврат Результат;
	
КонецФункции
 
Функция ПолучитьИДПоследнегоОбновления()
	
	Запрос = Новый Запрос;
	Запрос.Текст = 
	"ВЫБРАТЬ ПЕРВЫЕ 1
	|	СинхронизированныеДанные.ИДОбновления + 1 КАК ИДОбновления
	|ИЗ
	|	РегистрСведений.СинхронизированныеДанные КАК СинхронизированныеДанные
	|УПОРЯДОЧИТЬ ПО
	|	ИДОбновления УБЫВ";
	
	Выборка = Запрос.Выполнить().Выбрать();
	
	Если Выборка.Следующий() Тогда
		Возврат СлужебныеПроцедурыКлиентСервер.СтрокаИзЧисла(Выборка.ИДОбновления);
	Иначе
		Возврат "";
	КонецЕсли;
	
КонецФункции

Функция ОбработатьКомандыСообщения(Знач ТекстСообщения)
	
	Вероятности = НейронныеСети.ПолучитьВероятности(Справочники.ЛинейныеНейронныеСети.АнализТекстаСообщения, ТекстСообщения);
	
	Если Вероятности = Неопределено Тогда
		Возврат "Не обучена корректно нейронная сеть!";
	КонецЕсли; 
	
	Возврат Вероятности[0].Нейрон; 
					
КонецФункции

Функция ПолучитьИнтернетПроксиПоПараметрам(ПараметрыПрокси)
	
	Если Не ЗначениеЗаполнено(ПараметрыПрокси.Ссылка) Тогда
		Возврат Неопределено;
	КонецЕсли; 
	
	Результат = Новый ИнтернетПрокси;
	ЗаполнитьЗначенияСвойств(Результат, ПараметрыПрокси);
	Результат.Установить("https", ПараметрыПрокси.ТипПрокси +  "://" + ПараметрыПрокси.Сервер, ПараметрыПрокси.Порт, ПараметрыПрокси.Пользователь, ПараметрыПрокси.Пароль, Ложь);
	
	Возврат Результат;
	
КонецФункции

Функция ПолучитьПоследниеСообщения(Параметры)
	
	ИДПоследнегоОбновления = ПолучитьИДПоследнегоОбновления();
	Если ЗначениеЗаполнено(ИДПоследнегоОбновления) Тогда
		ТекстОтбора = "?offset=" + ИДПоследнегоОбновления;	
	Иначе
		ТекстОтбора = "";
	КонецЕсли;
	
	ПараметрыЗапроса = СлужебныеПроцедуры.ПолучитьПараметрыHTTPЗапроса();
	ПараметрыЗапроса.ТекстЗапроса = Параметры.ИДБота + "/getUpdates" + ТекстОтбора;
		
	Возврат СлужебныеПроцедуры.ВыполнитьHTTPЗапрос(Параметры, ПараметрыЗапроса).СтруктураОтвета.result;	
	
КонецФункции

Функция ПолучитьЗвуковойФайл(Параметры, СтруктураСообщения)
	
	ИДЗвуковогоФайла = СтруктураСообщения.voice.file_id;
	
	ПараметрыЗапроса = СлужебныеПроцедуры.ПолучитьПараметрыHTTPЗапроса();
	ПараметрыЗапроса.ТекстЗапроса = Параметры.ИДБота + "/getFile?file_id=" + ИДЗвуковогоФайла;
	ПутьКФайлу = СлужебныеПроцедуры.ВыполнитьHTTPЗапрос(Параметры, ПараметрыЗапроса).СтруктураОтвета.result.file_path;
	
	ПараметрыЗапроса.ТекстЗапроса = "/file/" + Параметры.ИДБота + "/" + ПутьКФайлу;
	ДД = СлужебныеПроцедуры.ВыполнитьHTTPЗапрос(Параметры, ПараметрыЗапроса).ДвоичныеДанныеОтвет;
	
	Возврат ДД;
	
КонецФункции
 
Функция ПолучитьРаскодированныйQRКод(ДанныеФото, Параметры)
	
	Для Каждого Фото Из ДанныеФото Цикл
		
		Если Фото.file_size < 1048576 Тогда
					
			ПараметрыЗапроса = СлужебныеПроцедуры.ПолучитьПараметрыHTTPЗапроса();
			ПараметрыЗапроса.ТекстЗапроса = Параметры.ИДБота + "/getFile?file_id=" + Фото.file_id;
			
			СтруктураОтвета = СлужебныеПроцедуры.ВыполнитьHTTPЗапрос(Параметры, ПараметрыЗапроса).СтруктураОтвета;
								
			ПараметрыСоединенияQR = Новый Структура;
			СоединениеQR = Новый HTTPСоединение("api.qrserver.com",443,,,,,Новый ЗащищенноеСоединениеOpenSSL);
			ПараметрыСоединенияQR.Вставить("Соединение", СоединениеQR);
			ПараметрыЗапроса.ТекстЗапроса = "/v1/read-qr-code/?fileurl=https://api.telegram.org/file/" 
											+ Параметры.ИДБота + "/" + СтруктураОтвета.result.file_path;
											
			СтруктураОтвета = СлужебныеПроцедуры.ВыполнитьHTTPЗапрос(ПараметрыСоединенияQR, ПараметрыЗапроса).СтруктураОтвета;
			Если СтруктураОтвета[0].symbol[0].data <> Неопределено Тогда
				ТекстСообщения = СтруктураОтвета[0].symbol[0].data;
				Прервать;
			КонецЕсли;
			
		КонецЕсли;
		
	КонецЦикла;
	
КонецФункции
 
#КонецОбласти


  